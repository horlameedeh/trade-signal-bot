from app.telegram.onboarding import handle_onboarding_command


def test_start_creates_user_and_returns_help():
    result = handle_onboarding_command(
        text="/start",
        telegram_user_id=77001,
        display_name="Test User",
    )

    assert result.handled is True
    assert result.ok is True
    assert "Welcome to TradeBot" in result.message
    assert "!myaccounts" in result.message


def test_whoami_returns_user_identity():
    result = handle_onboarding_command(
        text="!whoami",
        telegram_user_id=77002,
        display_name="Test User 2",
    )

    assert result.handled is True
    assert result.ok is True
    assert "Telegram ID: 77002" in result.message
    assert "Linked accounts:" in result.message


def test_unknown_onboarding_command_not_handled():
    result = handle_onboarding_command(
        text="hello",
        telegram_user_id=77003,
    )

    assert result.handled is False
