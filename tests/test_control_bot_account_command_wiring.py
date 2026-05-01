from cryptography.fernet import Fernet

from app.telegram.account_commands import handle_account_command


def test_control_bot_account_command_handler_contract(monkeypatch):
    monkeypatch.setenv("TRADEBOT_ADMIN_TELEGRAM_USER_IDS", "111")
    monkeypatch.setenv("TRADEBOT_SECRET_KEY", Fernet.generate_key().decode())

    result = handle_account_command(
        text="!addaccount wiring-ftmo",
        telegram_user_id=111,
    )

    assert result.handled is True
    assert result.ok is True
    assert "Account created" in result.message


def test_control_bot_account_command_rejects_non_admin(monkeypatch):
    monkeypatch.setenv("TRADEBOT_ADMIN_TELEGRAM_USER_IDS", "111")
    monkeypatch.setenv("TRADEBOT_SECRET_KEY", Fernet.generate_key().decode())

    result = handle_account_command(
        text="!addaccount wiring-blocked",
        telegram_user_id=222,
    )

    assert result.handled is True
    assert result.ok is False
    assert "Not authorized" in result.message
