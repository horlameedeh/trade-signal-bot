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


def _seed_user(db, *, telegram_user_id: int, display_name: str) -> str:
    user_id = str(uuid.uuid4())

    db.execute(
        text(
            """
            INSERT INTO users (user_id, telegram_user_id, display_name, role, is_active)
            VALUES (
              CAST(:user_id AS uuid), :telegram_user_id, :display_name, 'user', true
            )
            """
        ),
        {
            "user_id": user_id,
            "telegram_user_id": telegram_user_id,
            "display_name": display_name,
        },
    )
    db.commit()
    return user_id


def _seed_account(db, *, broker="vantage", platform="mt4", label=None) -> str:
    account_id = str(uuid.uuid4())
    label = label or f"terminal-route-{account_id}"
    user_id = str(uuid.uuid4())
    telegram_user_id = int(f"89{uuid.uuid4().int % 10**9:09d}")

    db.execute(
        text(
            """
            INSERT INTO users (user_id, telegram_user_id, display_name, role, is_active)
            VALUES (
              CAST(:user_id AS uuid), :telegram_user_id, :display_name, 'user', true
            )
            """
        ),
        {
            "user_id": user_id,
            "telegram_user_id": telegram_user_id,
            "display_name": f"terminal-route-user-{account_id}",
        },
    )

    db.execute(
        text(
            """
            INSERT INTO broker_accounts (
                            account_id, user_id, broker, platform, kind, label,
              base_currency, equity_start, equity_current,
              allowed_providers, is_active
            )
            VALUES (
                            CAST(:account_id AS uuid), CAST(:user_id AS uuid), :broker, :platform, 'personal_live', :label,
              'GBP', 500, 500,
              ARRAY[]::provider_code[], false
            )
            """
        ),
        {
            "account_id": account_id,
                        "user_id": user_id,
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
                            user_id,
              terminal_name,
              terminal_path,
              data_dir,
              port,
              status,
                            last_heartbeat,
              meta
            )
            VALUES (
              CAST(:session_id AS uuid),
              CAST(:account_id AS uuid),
                            (SELECT user_id FROM broker_accounts WHERE account_id = CAST(:account_id AS uuid)),
              :terminal_name,
              '/tmp/terminal.exe',
              '/tmp/data',
              9001,
              :status,
                            CASE WHEN :status IN ('starting', 'running') THEN now() ELSE NULL END,
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
        db.execute(
            text(
                "DELETE FROM users WHERE display_name = :display_name"
            ),
            {"display_name": f"terminal-route-user-{account_id}"},
        )
        db.commit()


def _cleanup_users(*user_ids: str) -> None:
    if not user_ids:
        return

    with SessionLocal() as db:
        for user_id in user_ids:
            db.execute(
                text("DELETE FROM users WHERE user_id = CAST(:user_id AS uuid)"),
                {"user_id": user_id},
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


def test_resolve_terminal_session_for_account_blocks_missing_account_owner():
    with SessionLocal() as db:
        account_id = _seed_account(
            db,
            broker="ftmo",
            platform="mt5",
            label="ownerless-account",
        )
        db.execute(
            text(
                "UPDATE broker_accounts SET user_id = NULL WHERE account_id = CAST(:account_id AS uuid)"
            ),
            {"account_id": account_id},
        )
        db.execute(
            text(
                """
                INSERT INTO terminal_sessions (
                  broker_account_id, user_id, terminal_name, terminal_path, data_dir, port, status, last_heartbeat
                )
                VALUES (
                  CAST(:account_id AS uuid), NULL, 'ownerless-terminal', '/tmp/mt5', '/tmp/data', 9901, 'running', now()
                )
                """
            ),
            {"account_id": account_id},
        )
        db.commit()

    try:
        with pytest.raises(TerminalSessionRoutingError, match="missing_account_owner"):
            resolve_terminal_session_for_account(broker_account_id=account_id)
    finally:
        _cleanup_account(account_id)


def test_resolve_terminal_session_for_account_blocks_missing_terminal_owner():
    with SessionLocal() as db:
        account_id = _seed_account(
            db,
            broker="ftmo",
            platform="mt5",
            label="missing-terminal-owner",
        )
        user_id = _seed_user(db, telegram_user_id=99001, display_name="Alice")
        db.execute(
            text(
                "UPDATE broker_accounts SET user_id = CAST(:user_id AS uuid) WHERE account_id = CAST(:account_id AS uuid)"
            ),
            {"account_id": account_id, "user_id": user_id},
        )
        db.execute(
            text(
                """
                INSERT INTO terminal_sessions (
                  broker_account_id, user_id, terminal_name, terminal_path, data_dir, port, status, last_heartbeat
                )
                VALUES (
                  CAST(:account_id AS uuid), NULL, 'missing-terminal-owner', '/tmp/mt5', '/tmp/data', 9902, 'running', now()
                )
                """
            ),
            {"account_id": account_id},
        )
        db.commit()

    try:
        with pytest.raises(TerminalSessionRoutingError, match="missing_terminal_owner"):
            resolve_terminal_session_for_account(broker_account_id=account_id)
    finally:
        _cleanup_account(account_id)
        _cleanup_users(user_id)


def test_resolve_terminal_session_for_account_blocks_user_mismatch():
    with SessionLocal() as db:
        account_id = _seed_account(
            db,
            broker="ftmo",
            platform="mt5",
            label="mismatch-owner",
        )
        alice_id = _seed_user(db, telegram_user_id=99011, display_name="Alice")
        bob_id = _seed_user(db, telegram_user_id=99012, display_name="Bob")

        db.execute(
            text(
                "UPDATE broker_accounts SET user_id = CAST(:user_id AS uuid) WHERE account_id = CAST(:account_id AS uuid)"
            ),
            {"account_id": account_id, "user_id": alice_id},
        )
        db.execute(
            text(
                """
                INSERT INTO terminal_sessions (
                  broker_account_id, user_id, terminal_name, terminal_path, data_dir, port, status, last_heartbeat
                )
                VALUES (
                  CAST(:account_id AS uuid), CAST(:terminal_user_id AS uuid), 'mismatch-terminal', '/tmp/mt5', '/tmp/data', 9903, 'running', now()
                )
                """
            ),
            {"account_id": account_id, "terminal_user_id": bob_id},
        )
        db.commit()

    try:
        with pytest.raises(TerminalSessionRoutingError, match="terminal_session_user_mismatch"):
            resolve_terminal_session_for_account(broker_account_id=account_id)
    finally:
        _cleanup_account(account_id)
        _cleanup_users(alice_id, bob_id)