from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timezone
from typing import Literal

from sqlalchemy import text

from app.db.session import SessionLocal

TerminalSessionStatus = Literal["starting", "running", "stopped", "failed", "closed"]


@dataclass(frozen=True)
class TerminalSession:
    session_id: str
    broker_account_id: str
    user_id: str | None
    broker_account_user_id: str | None
    terminal_name: str
    terminal_path: str | None
    data_dir: str | None
    port: int | None
    status: str


class TerminalSessionRoutingError(RuntimeError):
    pass


HEARTBEAT_STALE_AFTER_SECONDS = 90


def _is_stale_heartbeat(value) -> bool:
    if value is None:
        return True

    if isinstance(value, str):
        try:
            value = datetime.fromisoformat(value.replace("Z", "+00:00"))
        except ValueError:
            return True

    if value.tzinfo is None:
        value = value.replace(tzinfo=timezone.utc)

    age = datetime.now(timezone.utc) - value.astimezone(timezone.utc)
    return age.total_seconds() > HEARTBEAT_STALE_AFTER_SECONDS


def resolve_terminal_session_for_account(*, broker_account_id: str) -> TerminalSession:
    with SessionLocal() as db:
        rows = db.execute(
            text(
                """
                SELECT
                                    ts.session_id::text AS session_id,
                                    ts.broker_account_id::text AS broker_account_id,
                                    ts.user_id::text AS terminal_user_id,
                                    ba.user_id::text AS broker_account_user_id,
                                    ts.terminal_name,
                                    ts.terminal_path,
                                    ts.data_dir,
                                    ts.port,
                                    ts.status,
                                    ts.last_heartbeat
                                FROM terminal_sessions ts
                                JOIN broker_accounts ba
                                    ON ba.account_id = ts.broker_account_id
                                WHERE ts.broker_account_id = CAST(:broker_account_id AS uuid)
                                    AND ts.status IN ('starting', 'running')
                                ORDER BY ts.started_at DESC, ts.created_at DESC
                """
            ),
            {"broker_account_id": broker_account_id},
        ).mappings().all()

    if len(rows) == 0:
        raise TerminalSessionRoutingError(
            f"missing_terminal_session:broker_account_id={broker_account_id}"
        )

    if len(rows) > 1:
        raise TerminalSessionRoutingError(
            f"ambiguous_terminal_session:broker_account_id={broker_account_id}:count={len(rows)}"
        )

    row = rows[0]

    if _is_stale_heartbeat(row["last_heartbeat"]):
        raise TerminalSessionRoutingError(
            f"stale_terminal_session:broker_account_id={broker_account_id}:session_id={row['session_id']}"
        )

    broker_account_user_id = row["broker_account_user_id"]
    terminal_user_id = row["terminal_user_id"]

    if not broker_account_user_id:
        raise TerminalSessionRoutingError(
            f"missing_account_owner:broker_account_id={broker_account_id}"
        )

    if not terminal_user_id:
        raise TerminalSessionRoutingError(
            f"missing_terminal_owner:broker_account_id={broker_account_id}:session_id={row['session_id']}"
        )

    if terminal_user_id != broker_account_user_id:
        raise TerminalSessionRoutingError(
            f"terminal_session_user_mismatch:broker_account_id={broker_account_id}:session_id={row['session_id']}"
        )

    return TerminalSession(
        session_id=row["session_id"],
        broker_account_id=row["broker_account_id"],
        user_id=terminal_user_id,
        broker_account_user_id=broker_account_user_id,
        terminal_name=row["terminal_name"],
        terminal_path=row["terminal_path"],
        data_dir=row["data_dir"],
        port=row["port"],
        status=row["status"],
    )