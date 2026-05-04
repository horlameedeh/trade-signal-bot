from __future__ import annotations

import json
from dataclasses import dataclass

from sqlalchemy import text

from app.db.session import SessionLocal
from app.execution.base import ExecutionAdapter
from app.execution.live_executor import LiveExecutionResult
from app.execution.retry import RetryPolicy, execute_family_live_with_retry
from app.execution.terminal_sessions import (
    TerminalSessionRoutingError,
    resolve_terminal_session_for_account,
)
from app.risk.exposure import evaluate_family_prop_risk
from app.risk.global_safety import evaluate_global_safety
from app.services.alerts import alert_execution_failure, alert_trade_opened


@dataclass(frozen=True)
class GuardedExecutionResult:
    family_id: str
    allowed: bool
    requires_approval: bool
    blocked: bool
    risk_decision: str
    risk_reasons: list[str]
    execution_result: LiveExecutionResult | None


def _family_alert_context(*, family_id: str) -> dict:
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


def _write_global_safety_alert(*, family_id: str, decision: str, reasons: list[str]) -> None:
    action = "global_safety_block" if decision == "block" else "global_safety_requires_approval"

    with SessionLocal() as db:
        db.execute(
            text(
                """
                INSERT INTO control_actions (action, status, payload)
                VALUES (
                  :action,
                  'queued',
                  jsonb_build_object(
                    'source', 'global_safety_guard',
                                        'guard_type', 'global_safety',
                    'family_id', CAST(:family_id AS text),
                    'decision', CAST(:decision AS text),
                    'reasons', CAST(:reasons AS text[])
                  )
                )
                """
            ),
            {
                "action": action,
                "family_id": family_id,
                "decision": decision,
                "reasons": reasons,
            },
        )
        db.commit()


def _write_risk_alert(*, family_id: str, decision: str, reasons: list[str]) -> None:
    action = "risk_block" if decision == "block" else "risk_requires_approval"

    with SessionLocal() as db:
        db.execute(
            text(
                """
                INSERT INTO control_actions (action, status, payload)
                VALUES (
                  :action,
                  'queued',
                  jsonb_build_object(
                    'source', 'prop_risk_guard',
                                        'guard_type', 'prop_risk',
                    'family_id', CAST(:family_id AS text),
                    'decision', CAST(:decision AS text),
                    'reasons', CAST(:reasons AS jsonb)
                  )
                )
                """
            ),
            {
                "action": action,
                "family_id": family_id,
                "decision": decision,
                "reasons": json.dumps(reasons),
            },
        )
        db.commit()


def _family_account_id(*, family_id: str) -> str:
    with SessionLocal() as db:
        account_id = db.execute(
            text(
                """
                SELECT account_id::text
                FROM trade_families
                WHERE family_id = CAST(:family_id AS uuid)
                LIMIT 1
                """
            ),
            {"family_id": family_id},
        ).scalar()

    if not account_id:
        raise RuntimeError(f"trade_family account not found: {family_id}")

    return str(account_id)


def _write_terminal_routing_block(*, family_id: str, account_id: str, reason: str) -> None:
    with SessionLocal() as db:
        db.execute(
            text(
                """
                INSERT INTO control_actions (action, status, payload)
                VALUES (
                  'terminal_routing_block',
                  'queued',
                  jsonb_build_object(
                    'source', 'terminal_session_guard',
                    'family_id', CAST(:family_id AS text),
                    'account_id', CAST(:account_id AS text),
                    'reason', CAST(:reason AS text)
                  )
                )
                """
            ),
            {"family_id": family_id, "account_id": account_id, "reason": reason},
        )
        db.commit()


def _assert_terminal_session_routing(*, family_id: str) -> None:
    account_id = _family_account_id(family_id=family_id)

    try:
        resolve_terminal_session_for_account(broker_account_id=account_id)
    except TerminalSessionRoutingError as exc:
        _write_terminal_routing_block(
            family_id=family_id,
            account_id=account_id,
            reason=str(exc),
        )
        raise


def execute_family_with_prop_guard(
    *,
    family_id: str,
    adapter: ExecutionAdapter,
    daily_realized_pnl: str = "0",
    total_realized_pnl: str = "0",
    retry_policy: RetryPolicy | None = None,
) -> GuardedExecutionResult:
    global_safety = evaluate_global_safety(family_id=family_id)

    if global_safety.decision == "block":
        _write_global_safety_alert(
            family_id=family_id,
            decision=global_safety.decision,
            reasons=global_safety.reasons,
        )
        return GuardedExecutionResult(
            family_id=family_id,
            allowed=False,
            requires_approval=False,
            blocked=True,
            risk_decision=global_safety.decision,
            risk_reasons=global_safety.reasons,
            execution_result=None,
        )

    if global_safety.decision == "require_approval":
        _write_global_safety_alert(
            family_id=family_id,
            decision=global_safety.decision,
            reasons=global_safety.reasons,
        )
        return GuardedExecutionResult(
            family_id=family_id,
            allowed=False,
            requires_approval=True,
            blocked=False,
            risk_decision=global_safety.decision,
            risk_reasons=global_safety.reasons,
            execution_result=None,
        )

    risk = evaluate_family_prop_risk(
        family_id=family_id,
        daily_realized_pnl=daily_realized_pnl,
        total_realized_pnl=total_realized_pnl,
    )

    if risk.decision == "block":
        _write_risk_alert(family_id=family_id, decision=risk.decision, reasons=risk.reasons)
        return GuardedExecutionResult(
            family_id=family_id,
            allowed=False,
            requires_approval=False,
            blocked=True,
            risk_decision=risk.decision,
            risk_reasons=risk.reasons,
            execution_result=None,
        )

    if risk.decision == "require_approval":
        _write_risk_alert(family_id=family_id, decision=risk.decision, reasons=risk.reasons)
        return GuardedExecutionResult(
            family_id=family_id,
            allowed=False,
            requires_approval=True,
            blocked=False,
            risk_decision=risk.decision,
            risk_reasons=risk.reasons,
            execution_result=None,
        )

    _assert_terminal_session_routing(family_id=family_id)

    ctx = _family_alert_context(family_id=family_id)

    retry_result = execute_family_live_with_retry(
        family_id=family_id,
        adapter=adapter,
        policy=retry_policy,
    )

    execution = retry_result.execution_result

    if not retry_result.success or execution is None:
        return GuardedExecutionResult(
            family_id=family_id,
            allowed=False,
            requires_approval=False,
            blocked=True,
            risk_decision=risk.decision,
            risk_reasons=[*risk.reasons, "execution_retry_failed"],
            execution_result=None,
        )

    if execution.sent > 0:
        alert_trade_opened(
            family_id=family_id,
            broker=ctx.get("broker") or "unknown",
            platform=ctx.get("platform") or "unknown",
            symbol=ctx.get("symbol") or "unknown",
            data={
                "sent": execution.sent,
                "tickets_persisted": execution.tickets_persisted,
                "skipped_existing": execution.skipped_existing,
                "retry_attempts": retry_result.attempts,
            },
        )

    return GuardedExecutionResult(
        family_id=family_id,
        allowed=True,
        requires_approval=False,
        blocked=False,
        risk_decision=risk.decision,
        risk_reasons=risk.reasons,
        execution_result=execution,
    )
