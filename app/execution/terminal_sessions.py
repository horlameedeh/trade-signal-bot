from __future__ import annotations

from dataclasses import dataclass
from typing import Literal

from sqlalchemy import text

from app.db.session import SessionLocal

TerminalSessionStatus = Literal["starting", "running", "stopped", "failed", "closed"]


@dataclass(frozen=True)
class TerminalSession:
    session_id: str
    broker_account_id: str
    terminal_name: str
    terminal_path: str | None
    data_dir: str | None
    port: int | None
    status: str


class TerminalSessionRoutingError(RuntimeError):
    pass


def resolve_terminal_session_for_account(*, broker_account_id: str) -> TerminalSession:
    with SessionLocal() as db:
        rows = db.execute(
            text(
                """
                SELECT
                  session_id::text AS session_id,
                  broker_account_id::text AS broker_account_id,
                  terminal_name,
                  terminal_path,
                  data_dir,
                  port,
                  status
                FROM terminal_sessions
                WHERE broker_account_id = CAST(:broker_account_id AS uuid)
                  AND status IN ('starting', 'running')
                ORDER BY started_at DESC, created_at DESC
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
    return TerminalSession(
        session_id=row["session_id"],
        broker_account_id=row["broker_account_id"],
        terminal_name=row["terminal_name"],
        terminal_path=row["terminal_path"],
        data_dir=row["data_dir"],
        port=row["port"],
        status=row["status"],
    )