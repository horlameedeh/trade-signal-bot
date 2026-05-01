import pytest
from cryptography.fernet import Fernet
from sqlalchemy import text

from app.db.session import SessionLocal
from app.services.broker_credentials import (
    BrokerCredentialInput,
    get_broker_password,
    safe_show_account,
    upsert_broker_credentials,
)
from app.services.users import get_or_create_user

_TEST_TELEGRAM_IDS = (99111, 99222)
_TEST_LABEL = "shared-ftmo"


@pytest.fixture(autouse=True)
def _cleanup_test_users_and_creds():
    """Remove test users and their credentials before and after each test."""
    def cleanup():
        with SessionLocal() as db:
            db.execute(
                text(
                    """
                    DELETE FROM broker_credentials
                    WHERE user_id IN (
                        SELECT user_id FROM users WHERE telegram_user_id = ANY(:ids)
                    )
                    """
                ),
                {"ids": list(_TEST_TELEGRAM_IDS)},
            )
            db.execute(
                text(
                    "DELETE FROM user_control_chats WHERE user_id IN ("
                    "  SELECT user_id FROM users WHERE telegram_user_id = ANY(:ids)"
                    ")"
                ),
                {"ids": list(_TEST_TELEGRAM_IDS)},
            )
            db.execute(
                text("DELETE FROM users WHERE telegram_user_id = ANY(:ids)"),
                {"ids": list(_TEST_TELEGRAM_IDS)},
            )
            db.commit()

    cleanup()
    yield
    cleanup()


def test_same_account_label_is_isolated_by_user(monkeypatch):
    monkeypatch.setenv("TRADEBOT_SECRET_KEY", Fernet.generate_key().decode())

    alice = get_or_create_user(telegram_user_id=99111, display_name="Alice")
    bob = get_or_create_user(telegram_user_id=99222, display_name="Bob")

    label = "shared-ftmo"

    upsert_broker_credentials(
        BrokerCredentialInput(
            account_label=label,
            user_id=alice.user_id,
            broker="ftmo",
            platform="mt5",
            login="alice-login",
            password="alice-secret",
            server="Alice-Demo",
        )
    )

    upsert_broker_credentials(
        BrokerCredentialInput(
            account_label=label,
            user_id=bob.user_id,
            broker="ftmo",
            platform="mt5",
            login="bob-login",
            password="bob-secret",
            server="Bob-Demo",
        )
    )

    alice_show = safe_show_account(label, user_id=alice.user_id)
    bob_show = safe_show_account(label, user_id=bob.user_id)

    assert "alice-login" in alice_show
    assert "Alice-Demo" in alice_show
    assert "bob-login" not in alice_show
    assert "bob-secret" not in alice_show

    assert "bob-login" in bob_show
    assert "Bob-Demo" in bob_show
    assert "alice-login" not in bob_show
    assert "alice-secret" not in bob_show

    assert get_broker_password(label, user_id=alice.user_id) == "alice-secret"
    assert get_broker_password(label, user_id=bob.user_id) == "bob-secret"
