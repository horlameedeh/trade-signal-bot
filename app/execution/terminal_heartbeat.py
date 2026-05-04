from __future__ import annotations

from dataclasses import dataclass

from sqlalchemy import text

from app.db.session import SessionLocal


@dataclass(frozen=True)
class TerminalHeartbeatResult:
    updated: bool
    session_id: str
    terminal_name: str | None
    status: str | None


def touch_terminal_session(*, session_id: str, status: str = "running") -> TerminalHeartbeatResult:
    """
    Update last_heartbeat for a known terminal session.

    This intentionally refuses to create sessions. Sessions must be registered
    first so routing remains deterministic and auditable.
    """
    with SessionLocal() as db:
        row = db.execute(
            text(
                """
                UPDATE terminal_sessions
                SET
                  last_heartbeat = now(),
                  status = CAST(:status AS text),
                  updated_at = now()
                WHERE session_id = CAST(:session_id AS uuid)
                RETURNING
                  session_id::text AS session_id,
                  terminal_name,
                  status
                """
            ),
            {"session_id": session_id, "status": status},
        ).mappings().first()
        db.commit()

    if not row:
        return TerminalHeartbeatResult(
            updated=False,
            session_id=session_id,
            terminal_name=None,
            status=None,
        )

    return TerminalHeartbeatResult(
        updated=True,
        session_id=row["session_id"],
        terminal_name=row["terminal_name"],
        status=row["status"],
    )


def mark_terminal_session_stopped(*, session_id: str) -> TerminalHeartbeatResult:
    with SessionLocal() as db:
        row = db.execute(
            text(
                """
                UPDATE terminal_sessions
                SET
                  status = 'stopped',
                                    ended_at = now(),
                  updated_at = now()
                WHERE session_id = CAST(:session_id AS uuid)
                RETURNING
                  session_id::text AS session_id,
                  terminal_name,
                  status
                """
            ),
            {"session_id": session_id},
        ).mappings().first()
        db.commit()

    if not row:
        return TerminalHeartbeatResult(
            updated=False,
            session_id=session_id,
            terminal_name=None,
            status=None,
        )

    return TerminalHeartbeatResult(
        updated=True,
        session_id=row["session_id"],
        terminal_name=row["terminal_name"],
        status=row["status"],
    )
