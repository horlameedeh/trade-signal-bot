from __future__ import annotations

from dataclasses import dataclass

from app.services.tenant_context import get_user_accounts
from app.services.users import get_or_create_user


@dataclass(frozen=True)
class OnboardingResult:
    handled: bool
    ok: bool
    message: str


def handle_onboarding_command(
    *,
    text: str,
    telegram_user_id: int | None,
    display_name: str | None = None,
) -> OnboardingResult:
    raw = ((text or "").strip().splitlines()[0] if (text or "").strip() else "")

    if raw not in {"/start", "!whoami"}:
        return OnboardingResult(False, False, "")

    if telegram_user_id is None:
        return OnboardingResult(True, False, "❌ Could not identify Telegram user.")

    user = get_or_create_user(
        telegram_user_id=telegram_user_id,
        display_name=display_name,
    )

    accounts = get_user_accounts(user_id=user.user_id)

    if raw == "/start":
        return OnboardingResult(
            True,
            True,
            (
                "✅ Welcome to TradeBot.\n\n"
                f"User: {user.display_name or user.telegram_user_id}\n"
                f"Role: {user.role}\n\n"
                "Available commands:\n"
                "!whoami\n"
                "!myaccounts\n"
                "!addaccount <label>\n"
                "!showaccount <label>\n\n"
                "Next step: configure or link a broker account."
            ),
        )

    account_lines = ["Linked accounts:"]
    if accounts:
        for a in accounts:
            active = "active" if a.is_active else "inactive"
            account_lines.append(f"- {a.label or a.account_id}: {a.broker}/{a.platform} ({active})")
    else:
        account_lines.append("- none")

    return OnboardingResult(
        True,
        True,
        (
            "TradeBot User\n"
            f"Telegram ID: {user.telegram_user_id}\n"
            f"User ID: {user.user_id}\n"
            f"Role: {user.role}\n"
            f"Active: {user.is_active}\n\n"
            + "\n".join(account_lines)
        ),
    )
