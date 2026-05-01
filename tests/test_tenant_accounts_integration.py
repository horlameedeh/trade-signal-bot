import uuid

import pytest
from sqlalchemy import text

from app.db.session import SessionLocal
from app.services.tenant_context import (
    assert_account_belongs_to_user,
    assign_account_to_user,
    get_user_account_by_label,
    get_user_accounts,
    resolve_active_user_account,
)
from app.services.users import get_or_create_user


pytestmark = pytest.mark.integration


@pytest.fixture
def db_session():
    with SessionLocal() as db:
        try:
            db.execute(text("DELETE FROM broker_accounts WHERE label LIKE 'tenant-%'"))
            db.execute(text("DELETE FROM users WHERE telegram_user_id IN (88111, 88222)"))
            db.commit()
            yield db
        finally:
            db.execute(text("DELETE FROM broker_accounts WHERE label LIKE 'tenant-%'"))
            db.execute(text("DELETE FROM users WHERE telegram_user_id IN (88111, 88222)"))
            db.commit()


def _seed_account(db_session, *, label: str, broker: str = "ftmo", platform: str = "mt5") -> str:
    account_id = str(uuid.uuid4())

    db_session.execute(
        text(
            """
            INSERT INTO broker_accounts (
              account_id, broker, platform, kind, label,
              allowed_providers, equity_start, equity_current, is_active
            )
            VALUES (
              CAST(:account_id AS uuid), :broker, :platform, 'personal_live', :label,
              ARRAY[]::provider_code[], 10000, 10000, true
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
    db_session.commit()
    return account_id


def test_user_accounts_are_isolated(db_session):
    alice = get_or_create_user(telegram_user_id=88111, display_name="Alice")
    bob = get_or_create_user(telegram_user_id=88222, display_name="Bob")

    alice_account = _seed_account(db_session, label="tenant-shared")
    bob_account = _seed_account(db_session, label="tenant-shared")

    assign_account_to_user(account_id=alice_account, user_id=alice.user_id)
    assign_account_to_user(account_id=bob_account, user_id=bob.user_id)

    alice_accounts = get_user_accounts(user_id=alice.user_id)
    bob_accounts = get_user_accounts(user_id=bob.user_id)

    assert {a.account_id for a in alice_accounts} == {alice_account}
    assert {a.account_id for a in bob_accounts} == {bob_account}

    assert get_user_account_by_label(user_id=alice.user_id, label="tenant-shared").account_id == alice_account
    assert get_user_account_by_label(user_id=bob.user_id, label="tenant-shared").account_id == bob_account


def test_resolve_active_user_account_is_scoped(db_session):
    alice = get_or_create_user(telegram_user_id=88111, display_name="Alice")
    bob = get_or_create_user(telegram_user_id=88222, display_name="Bob")

    alice_account = _seed_account(db_session, label="tenant-alice", broker="ftmo", platform="mt5")
    bob_account = _seed_account(db_session, label="tenant-bob", broker="ftmo", platform="mt5")

    assign_account_to_user(account_id=alice_account, user_id=alice.user_id)
    assign_account_to_user(account_id=bob_account, user_id=bob.user_id)

    resolved_alice = resolve_active_user_account(user_id=alice.user_id, broker="ftmo", platform="mt5")
    resolved_bob = resolve_active_user_account(user_id=bob.user_id, broker="ftmo", platform="mt5")

    assert resolved_alice is not None
    assert resolved_bob is not None
    assert resolved_alice.account_id == alice_account
    assert resolved_bob.account_id == bob_account


def test_assert_account_belongs_to_user_blocks_cross_user_access(db_session):
    alice = get_or_create_user(telegram_user_id=88111, display_name="Alice")
    bob = get_or_create_user(telegram_user_id=88222, display_name="Bob")

    alice_account = _seed_account(db_session, label="tenant-alice")
    assign_account_to_user(account_id=alice_account, user_id=alice.user_id)

    assert_account_belongs_to_user(account_id=alice_account, user_id=alice.user_id)

    with pytest.raises(PermissionError):
        assert_account_belongs_to_user(account_id=alice_account, user_id=bob.user_id)
