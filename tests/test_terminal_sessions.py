from __future__ import annotations

import uuid

import pytest
from sqlalchemy import text

from app.db.session import SessionLocal
from app.execution.terminal_sessions import (
    TerminalSessionRoutingError,
    resolve_terminal_session_for_account,
)


def _insert_terminal_test_account(*, db, account_id: str, label: str) -> None:
    db.execute(
        text(
            """
            INSERT INTO broker_accounts (
              account_id, broker, platform, kind, label,
              base_currency, equity_start, equity_current,
              allowed_providers, is_active
            )
            VALUES (
              CAST(:account_id AS uuid), 'vantage', 'mt4', 'personal_live', :label,
              'GBP', 500, 500,
              ARRAY[]::provider_code[], false
            )
            """
        ),
        {"account_id": account_id, "label": label},
    )


def test_terminal_sessions_table_exists() -> None:
    with SessionLocal() as db:
        exists = db.execute(
            text(
                """
                SELECT EXISTS (
                  SELECT 1
                  FROM information_schema.tables
                  WHERE table_schema = 'public'
                    AND table_name = 'terminal_sessions'
                )
                """
            )
        ).scalar()

    assert exists is True


def test_terminal_sessions_can_insert_and_close() -> None:
    with SessionLocal() as db:
        broker_account_id = str(uuid.uuid4())
        _insert_terminal_test_account(
            db=db,
            account_id=broker_account_id,
            label="terminal-session-test",
        )

        session_id = db.execute(
            text(
                """
                INSERT INTO terminal_sessions (
                  broker_account_id, terminal_name, terminal_path, data_dir, port, status, meta
                )
                VALUES (
                  CAST(:broker_account_id AS uuid), :terminal_name, :terminal_path, :data_dir, :port, 'running',
                  jsonb_build_object('source', 'pytest')
                )
                RETURNING session_id::text
                """
            ),
            {
                "broker_account_id": broker_account_id,
                "terminal_name": "pytest-terminal-session",
                "terminal_path": "/Applications/MetaTrader 5.app",
                "data_dir": "/tmp/pytest-terminal-session",
                "port": 443,
            },
        ).scalar()
        db.commit()

        row = db.execute(
            text(
                """
                SELECT terminal_name, status, meta->>'source' AS source
                FROM terminal_sessions
                WHERE session_id = CAST(:session_id AS uuid)
                """
            ),
            {"session_id": session_id},
        ).mappings().first()

        assert row is not None
        assert row["terminal_name"] == "pytest-terminal-session"
        assert row["status"] == "running"
        assert row["source"] == "pytest"

        db.execute(
            text(
                """
                UPDATE terminal_sessions
                SET status = 'closed', ended_at = now()
                WHERE session_id = CAST(:session_id AS uuid)
                """
            ),
            {"session_id": session_id},
        )
        db.commit()

        closed = db.execute(
            text(
                """
                SELECT status, ended_at IS NOT NULL AS has_ended_at
                FROM terminal_sessions
                WHERE session_id = CAST(:session_id AS uuid)
                """
            ),
            {"session_id": session_id},
        ).mappings().first()

        db.execute(
            text(
                "DELETE FROM terminal_sessions WHERE session_id = CAST(:session_id AS uuid)"
            ),
            {"session_id": session_id},
        )
        db.execute(
            text(
                "DELETE FROM broker_accounts WHERE account_id = CAST(:account_id AS uuid)"
            ),
            {"account_id": broker_account_id},
        )
        db.commit()

    assert closed is not None
    assert closed["status"] == "closed"
    assert closed["has_ended_at"] is True


def test_resolve_terminal_session_for_account_returns_running_session() -> None:
    broker_account_id = str(uuid.uuid4())

    with SessionLocal() as db:
        _insert_terminal_test_account(
            db=db,
            account_id=broker_account_id,
            label="terminal-resolve-test",
        )
        db.execute(
            text(
                """
                INSERT INTO terminal_sessions (
                  broker_account_id, terminal_name, terminal_path, data_dir, port, status
                )
                VALUES (
                  CAST(:broker_account_id AS uuid), 'resolve-terminal', '/Applications/MetaTrader 5.app',
                  '/tmp/resolve-terminal', 8443, 'running'
                )
                """
            ),
            {"broker_account_id": broker_account_id},
        )
        db.commit()

    try:
        session = resolve_terminal_session_for_account(broker_account_id=broker_account_id)
        assert session.broker_account_id == broker_account_id
        assert session.terminal_name == "resolve-terminal"
        assert session.status == "running"
    finally:
        with SessionLocal() as db:
            db.execute(
                text(
                    "DELETE FROM terminal_sessions WHERE broker_account_id = CAST(:account_id AS uuid)"
                ),
                {"account_id": broker_account_id},
            )
            db.execute(
                text(
                    "DELETE FROM broker_accounts WHERE account_id = CAST(:account_id AS uuid)"
                ),
                {"account_id": broker_account_id},
            )
            db.commit()


def test_resolve_terminal_session_for_account_raises_when_missing() -> None:
    with pytest.raises(TerminalSessionRoutingError, match="missing_terminal_session"):
        resolve_terminal_session_for_account(
            broker_account_id="00000000-0000-0000-0000-000000000001"
        )