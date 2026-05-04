from __future__ import annotations

import uuid

from sqlalchemy import text

from app.db.session import SessionLocal
from app.execution.terminal_heartbeat import (
    mark_terminal_session_stopped,
    touch_terminal_session,
)


def _seed_terminal_session() -> str:
    account_id = str(uuid.uuid4())
    session_id = str(uuid.uuid4())

    with SessionLocal() as db:
        db.execute(
            text(
                """
                INSERT INTO broker_accounts (
                  account_id, broker, platform, kind, label,
                  base_currency, equity_start, equity_current,
                  allowed_providers, is_active
                )
                VALUES (
                  CAST(:account_id AS uuid), 'vantage', 'mt5', 'personal_live', :label,
                  'GBP', 500, 500,
                  ARRAY[]::provider_code[], false
                )
                """
            ),
            {"account_id": account_id, "label": f"heartbeat-writer-{account_id}"},
        )

        db.execute(
            text(
                """
                INSERT INTO terminal_sessions (
                  session_id, broker_account_id, terminal_name,
                  terminal_path, data_dir, port, status, last_heartbeat, meta
                )
                VALUES (
                  CAST(:session_id AS uuid), CAST(:account_id AS uuid), :terminal_name,
                  '/tmp/terminal.exe', '/tmp/data', 9301, 'starting',
                  now() - interval '10 minutes', '{}'::jsonb
                )
                """
            ),
            {
                "session_id": session_id,
                "account_id": account_id,
                "terminal_name": f"heartbeat-writer-terminal-{session_id}",
            },
        )
        db.commit()

    return session_id


def test_touch_terminal_session_updates_known_session():
    session_id = _seed_terminal_session()

    result = touch_terminal_session(session_id=session_id)

    assert result.updated is True
    assert result.session_id == session_id
    assert result.status == "running"

    with SessionLocal() as db:
        row = db.execute(
            text(
                """
                SELECT status, last_heartbeat
                FROM terminal_sessions
                WHERE session_id = CAST(:session_id AS uuid)
                """
            ),
            {"session_id": session_id},
        ).mappings().one()

    assert row["status"] == "running"
    assert row["last_heartbeat"] is not None


def test_touch_terminal_session_refuses_unknown_session():
    result = touch_terminal_session(session_id=str(uuid.uuid4()))

    assert result.updated is False


def test_mark_terminal_session_stopped_marks_known_session():
    session_id = _seed_terminal_session()

    result = mark_terminal_session_stopped(session_id=session_id)

    assert result.updated is True
    assert result.status == "stopped"

    with SessionLocal() as db:
        status = db.execute(
            text(
                """
                SELECT status
                FROM terminal_sessions
                WHERE session_id = CAST(:session_id AS uuid)
                """
            ),
            {"session_id": session_id},
        ).scalar()

    assert status == "stopped"
