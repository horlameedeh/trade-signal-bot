import os

from cryptography.fernet import Fernet

from app.services.broker_credentials import (
    BrokerCredentialInput,
    ensure_credentials_table,
    get_broker_password,
    safe_show_account,
    upsert_broker_credentials,
)


def test_credentials_encrypt_and_show_safely(monkeypatch):
    monkeypatch.setenv("TRADEBOT_SECRET_KEY", Fernet.generate_key().decode())

    label = "test-ftmo-secure"
    ensure_credentials_table()

    view = upsert_broker_credentials(
        BrokerCredentialInput(
            account_label=label,
            broker="ftmo",
            platform="mt5",
            login="123456",
            password="super-secret",
            server="FTMO-Demo",
        )
    )

    assert view.account_label == label
    assert view.login == "123456"
    assert view.server == "FTMO-Demo"
    assert view.has_password is True
    assert get_broker_password(label) == "super-secret"

    shown = safe_show_account(label)

    assert "super-secret" not in shown
    assert "Password: configured" in shown
