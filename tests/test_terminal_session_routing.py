from __future__ import annotations

import uuid
from contextlib import contextmanager

import pytest
from sqlalchemy import text

from app.db.session import SessionLocal
from app.execution import terminal_sessions as terminal_sessions_module
from app.execution.terminal_sessions import (
    TerminalSessionRoutingError,
    resolve_terminal_session_for_account,
)


def _seed_account(db, *, broker="vantage", platform="mt4", label=None) -> str:
    account_id = str(uuid.uuid4())
    label = label or f"terminal-route-{account_id}"

    db.execute(
        text(
            """
            INSERT INTO broker_accounts (
              account_id, broker, platform, kind, label,
              base_currency, equity_start, equity_current,
              allowed_providers, is_active
            )
            VALUES (
              CAST(:account_id AS uuid), :broker, :platform, 'personal_live', :label,
              'GBP', 500, 500,
              ARRAY[]::provider_code[], false
            )
            """
        ),
        {
            "account_id": account_id,
            "broker": broker,
            "platform": platform,
            "label": label,
        },
    )
    db.commit()
    return account_id


def _seed_session(db, *, account_id: str, status: str = "running", name: str | None = None) -> str:
    session_id = str(uuid.uuid4())
    name = name or f"terminal-{session_id}"

    db.execute(
        text(
            """
            INSERT INTO terminal_sessions (
              session_id,
              broker_account_id,
              terminal_name,
              terminal_path,
              data_dir,
              port,
              status,
              meta
            )
            VALUES (
              CAST(:session_id AS uuid),
              CAST(:account_id AS uuid),
              :terminal_name,
              '/tmp/terminal.exe',
              '/tmp/data',
              9001,
              :status,
              '{}'::jsonb
            )
            """
        ),
        {
            "session_id": session_id,
            "account_id": account_id,
            "terminal_name": name,
            "status": status,
        },
    )
    db.commit()
    return session_id


def _cleanup_account(account_id: str) -> None:
    with SessionLocal() as db:
        db.execute(
            text(
                "DELETE FROM terminal_sessions WHERE broker_account_id = CAST(:account_id AS uuid)"
            ),
            {"account_id": account_id},
        )
        db.execute(
            text(
                "DELETE FROM broker_accounts WHERE account_id = CAST(:account_id AS uuid)"
            ),
            {"account_id": account_id},
        )
        db.commit()


def test_resolve_terminal_session_for_account_returns_single_running_session():
    with SessionLocal() as db:
        account_id = _seed_account(db)
        session_id = _seed_session(db, account_id=account_id, status="running")

    try:
        result = resolve_terminal_session_for_account(broker_account_id=account_id)

        assert result.session_id == session_id
        assert result.broker_account_id == account_id
        assert result.status == "running"
    finally:
        _cleanup_account(account_id)


def test_resolve_terminal_session_for_account_ignores_closed_sessions():
    with SessionLocal() as db:
        account_id = _seed_account(db)
        _seed_session(db, account_id=account_id, status="closed")
        running_id = _seed_session(db, account_id=account_id, status="running")

    try:
        result = resolve_terminal_session_for_account(broker_account_id=account_id)

        assert result.session_id == running_id
    finally:
        _cleanup_account(account_id)


def test_resolve_terminal_session_for_account_blocks_missing_session():
    with SessionLocal() as db:
        account_id = _seed_account(db)

    try:
        with pytest.raises(TerminalSessionRoutingError, match="missing_terminal_session"):
            resolve_terminal_session_for_account(broker_account_id=account_id)
    finally:
        _cleanup_account(account_id)


def test_resolve_terminal_session_for_account_blocks_ambiguous_sessions(monkeypatch):
    rows = [
        {
            "session_id": str(uuid.uuid4()),
            "broker_account_id": str(uuid.uuid4()),
            "terminal_name": "terminal-a",
            "terminal_path": "/tmp/terminal-a.exe",
            "data_dir": "/tmp/data-a",
            "port": 9001,
            "status": "running",
        },
        {
            "session_id": str(uuid.uuid4()),
            "broker_account_id": str(uuid.uuid4()),
            "terminal_name": "terminal-b",
            "terminal_path": "/tmp/terminal-b.exe",
            "data_dir": "/tmp/data-b",
            "port": 9002,
            "status": "starting",
        },
    ]

    class _FakeResult:
        def mappings(self):
            return self

        def all(self):
            return rows

    class _FakeSession:
        def execute(self, *_args, **_kwargs):
            return _FakeResult()

    @contextmanager
    def _fake_session_local():
        yield _FakeSession()

    monkeypatch.setattr(terminal_sessions_module, "SessionLocal", _fake_session_local)

    with pytest.raises(TerminalSessionRoutingError, match="ambiguous_terminal_session"):
        resolve_terminal_session_for_account(
            broker_account_id="00000000-0000-0000-0000-000000000001"
        )