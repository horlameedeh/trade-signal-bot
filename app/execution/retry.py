from __future__ import annotations

import time
from dataclasses import dataclass
from typing import Callable, TypeVar

from sqlalchemy import text

from app.db.session import SessionLocal
from app.execution.base import ExecutionAdapter
from app.execution.live_executor import LiveExecutionResult, execute_family_live
from app.services.alerts import alert_execution_failure


T = TypeVar("T")


@dataclass(frozen=True)
class RetryPolicy:
    max_attempts: int = 3
    base_delay_seconds: float = 0.1
    backoff_multiplier: float = 2.0


@dataclass(frozen=True)
class RetryExecutionResult:
    family_id: str
    success: bool
    attempts: int
    dead_lettered: bool
    execution_result: LiveExecutionResult | None
    last_error: str | None


def compute_backoff_delay(*, attempt_number: int, policy: RetryPolicy) -> float:
    if attempt_number <= 1:
        return 0.0
    return policy.base_delay_seconds * (policy.backoff_multiplier ** (attempt_number - 2))


def _record_retry_event(
    *,
    family_id: str,
    attempt: int,
    status: str,
    error: str | None = None,
) -> None:
    with SessionLocal() as db:
        db.execute(
            text(
                """
                INSERT INTO control_actions (action, status, payload)
                VALUES (
                  'execution_retry',
                  :status,
                  jsonb_build_object(
                    'source', 'execution_retry',
                    'family_id', CAST(:family_id AS text),
                    'attempt', :attempt,
                    'error', CAST(:error AS text)
                  )
                )
                """
            ),
            {
                "family_id": family_id,
                "attempt": attempt,
                "status": status,
                "error": error,
            },
        )
        db.commit()


def _record_dead_letter(*, family_id: str, attempts: int, error: str) -> None:
    with SessionLocal() as db:
        db.execute(
            text(
                """
                INSERT INTO control_actions (action, status, payload)
                VALUES (
                  'dead_letter:execution',
                  'queued',
                  jsonb_build_object(
                    'source', 'execution_retry',
                    'family_id', CAST(:family_id AS text),
                    'attempts', :attempts,
                    'error', CAST(:error AS text)
                  )
                )
                """
            ),
            {
                "family_id": family_id,
                "attempts": attempts,
                "error": error,
            },
        )
        db.commit()


def _family_context(*, family_id: str) -> dict:
    with SessionLocal() as db:
        row = db.execute(
            text(
                """
                SELECT
                  tf.family_id::text AS family_id,
                  ba.broker,
                  ba.platform,
                  tf.broker_symbol
                FROM trade_families tf
                JOIN broker_accounts ba ON ba.account_id = tf.account_id
                WHERE tf.family_id = CAST(:family_id AS uuid)
                LIMIT 1
                """
            ),
            {"family_id": family_id},
        ).mappings().first()

    if not row:
        return {"family_id": family_id}

    return {
        "family_id": row["family_id"],
        "broker": row["broker"],
        "platform": row["platform"],
        "symbol": row["broker_symbol"],
    }


def run_with_retry(
    *,
    family_id: str,
    operation: Callable[[], T],
    policy: RetryPolicy | None = None,
    sleep_fn: Callable[[float], None] = time.sleep,
) -> tuple[T | None, int, str | None]:
    policy = policy or RetryPolicy()
    last_error: str | None = None

    for attempt in range(1, policy.max_attempts + 1):
        delay = compute_backoff_delay(attempt_number=attempt, policy=policy)
        if delay > 0:
            sleep_fn(delay)

        try:
            result = operation()
            _record_retry_event(
                family_id=family_id,
                attempt=attempt,
                status="succeeded",
                error=None,
            )
            return result, attempt, None
        except Exception as exc:
            last_error = str(exc)
            _record_retry_event(
                family_id=family_id,
                attempt=attempt,
                status="failed",
                error=last_error,
            )

    return None, policy.max_attempts, last_error


def execute_family_live_with_retry(
    *,
    family_id: str,
    adapter: ExecutionAdapter,
    policy: RetryPolicy | None = None,
    sleep_fn: Callable[[float], None] = time.sleep,
) -> RetryExecutionResult:
    policy = policy or RetryPolicy()

    result, attempts, last_error = run_with_retry(
        family_id=family_id,
        operation=lambda: execute_family_live(family_id=family_id, adapter=adapter),
        policy=policy,
        sleep_fn=sleep_fn,
    )

    if result is not None:
        return RetryExecutionResult(
            family_id=family_id,
            success=True,
            attempts=attempts,
            dead_lettered=False,
            execution_result=result,
            last_error=None,
        )

    error = last_error or "unknown execution failure"
    _record_dead_letter(family_id=family_id, attempts=attempts, error=error)

    ctx = _family_context(family_id=family_id)
    alert_execution_failure(
        message=f"Execution failed after {attempts} attempts: {error}",
        family_id=family_id,
        broker=ctx.get("broker"),
        platform=ctx.get("platform"),
        symbol=ctx.get("symbol"),
        data={"attempts": attempts},
    )

    return RetryExecutionResult(
        family_id=family_id,
        success=False,
        attempts=attempts,
        dead_lettered=True,
        execution_result=None,
        last_error=error,
    )
