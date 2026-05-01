from cryptography.fernet import Fernet

from app.services.broker_credentials import get_broker_password, safe_show_account
from app.telegram.account_commands import handle_account_command, is_admin_user


def test_admin_user_check(monkeypatch):
    monkeypatch.setenv("TRADEBOT_ADMIN_TELEGRAM_USER_IDS", "111,222")

    assert is_admin_user(111) is True
    assert is_admin_user(222) is True
    assert is_admin_user(333) is False
    assert is_admin_user(None) is False


def test_non_admin_blocked(monkeypatch):
    monkeypatch.setenv("TRADEBOT_ADMIN_TELEGRAM_USER_IDS", "111")
    monkeypatch.setenv("TRADEBOT_SECRET_KEY", Fernet.generate_key().decode())

    result = handle_account_command(
        text="!addaccount blocked-account",
        telegram_user_id=999,
    )

    assert result.handled is True
    assert result.ok is False
    assert "Not authorized" in result.message


def test_full_account_setup_via_commands(monkeypatch):
    monkeypatch.setenv("TRADEBOT_ADMIN_TELEGRAM_USER_IDS", "111")
    monkeypatch.setenv("TRADEBOT_SECRET_KEY", Fernet.generate_key().decode())

    label = "cmd-ftmo-demo"

    assert handle_account_command(text=f"!addaccount {label}", telegram_user_id=111).ok
    assert handle_account_command(text=f"!setbroker {label} ftmo", telegram_user_id=111).ok
    assert handle_account_command(text=f"!setmt {label} mt5", telegram_user_id=111).ok
    assert handle_account_command(text=f"!setlogin {label} 1513243920", telegram_user_id=111).ok

    password_result = handle_account_command(
        text=f"!setpassword {label} very-secret-password",
        telegram_user_id=111,
    )
    assert password_result.ok
    assert "very-secret-password" not in password_result.message

    assert handle_account_command(text=f"!setserver {label} FTMO-Demo", telegram_user_id=111).ok

    shown = handle_account_command(text=f"!showaccount {label}", telegram_user_id=111)

    assert shown.ok
    assert "Broker: ftmo" in shown.message
    assert "Platform: mt5" in shown.message
    assert "Login: 1513243920" in shown.message
    assert "Server: FTMO-Demo" in shown.message
    assert "Password: configured" in shown.message
    assert "very-secret-password" not in shown.message

    assert get_broker_password(label) == "very-secret-password"
    assert "very-secret-password" not in safe_show_account(label)


def test_invalid_platform(monkeypatch):
    monkeypatch.setenv("TRADEBOT_ADMIN_TELEGRAM_USER_IDS", "111")
    monkeypatch.setenv("TRADEBOT_SECRET_KEY", Fernet.generate_key().decode())

    result = handle_account_command(
        text="!setmt account mt6",
        telegram_user_id=111,
    )

    assert result.handled is True
    assert result.ok is False
    assert "mt4 or mt5" in result.message


def test_unknown_command_not_handled(monkeypatch):
    monkeypatch.setenv("TRADEBOT_ADMIN_TELEGRAM_USER_IDS", "111")

    result = handle_account_command(
        text="!somethingelse",
        telegram_user_id=111,
    )

    assert result.handled is False
