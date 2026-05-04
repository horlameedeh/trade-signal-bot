from __future__ import annotations

import uuid

import pytest
from sqlalchemy import text

from app.db.session import SessionLocal
from app.execution.terminal_sessions import (
    TerminalSessionRoutingError,
    resolve_terminal_session_for_account,
)


def _seed_account_and_session(*, heartbeat_sql: str) -> str:
    account_id = str(uuid.uuid4())

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
            {"account_id": account_id, "label": f"heartbeat-test-{account_id}"},
        )

        db.execute(
            text(
                f"""
                INSERT INTO terminal_sessions (
                  broker_account_id, terminal_name, terminal_path,
                  data_dir, port, status, last_heartbeat, meta
                )
                VALUES (
                  CAST(:account_id AS uuid), :terminal_name, '/tmp/terminal.exe',
                  '/tmp/data', 9201, 'running', {heartbeat_sql}, '{{}}'::jsonb
                )
                """
            ),
            {"account_id": account_id, "terminal_name": f"heartbeat-terminal-{account_id}"},
        )
        db.commit()

    return account_id


def test_resolve_terminal_session_accepts_fresh_heartbeat():
    account_id = _seed_account_and_session(heartbeat_sql="now()")

    session = resolve_terminal_session_for_account(broker_account_id=account_id)

    assert session.broker_account_id == account_id
    assert session.status == "running"


def test_resolve_terminal_session_blocks_missing_heartbeat():
    account_id = _seed_account_and_session(heartbeat_sql="NULL")

    with pytest.raises(TerminalSessionRoutingError, match="stale_terminal_session"):
        resolve_terminal_session_for_account(broker_account_id=account_id)


def test_resolve_terminal_session_blocks_stale_heartbeat():
    account_id = _seed_account_and_session(heartbeat_sql="now() - interval '10 minutes'")

    with pytest.raises(TerminalSessionRoutingError, match="stale_terminal_session"):
        resolve_terminal_session_for_account(broker_account_id=account_id)
