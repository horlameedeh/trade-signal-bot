from __future__ import annotations

import os
from dataclasses import dataclass

from app.services.users import get_or_create_user
from app.services.tenant_context import get_user_accounts
from app.services.broker_credentials import (
    BrokerCredentialInput,
    safe_show_account,
    upsert_broker_credentials,
)


@dataclass(frozen=True)
class AccountCommandResult:
    handled: bool
    ok: bool
    message: str


def _admin_ids() -> set[int]:
    raw = os.getenv("TRADEBOT_ADMIN_TELEGRAM_USER_IDS", "")
    return {int(x.strip()) for x in raw.split(",") if x.strip()}


def is_admin_user(user_id: int | None) -> bool:
    if user_id is None:
        return False
    return user_id in _admin_ids()


def _usage() -> str:
    return (
        "Broker account commands:\n"
        "!addaccount <label>\n"
        "!setbroker <label> <broker>\n"
        "!setmt <label> <mt4|mt5>\n"
        "!setlogin <label> <login>\n"
        "!setpassword <label> <password>\n"
        "!setserver <label> <server>\n"
        "!showaccount <label>\n"
        "!myaccounts"
    )


def handle_account_command(*, text: str, telegram_user_id: int | None) -> AccountCommandResult:
    raw = ((text or "").strip().splitlines()[0] if (text or "").strip() else "")
    if not raw.startswith("!"):
        return AccountCommandResult(handled=False, ok=False, message="")

    parts = raw.split(maxsplit=2)
    command = parts[0].lower()

    supported = {
        "!addaccount",
        "!setbroker",
        "!setmt",
        "!setlogin",
        "!setpassword",
        "!setserver",
        "!showaccount",
        "!myaccounts",
    }

    if command not in supported:
        return AccountCommandResult(handled=False, ok=False, message="")

    if not is_admin_user(telegram_user_id):
        return AccountCommandResult(
            handled=True,
            ok=False,
            message="❌ Not authorized.",
        )

    user = get_or_create_user(telegram_user_id=telegram_user_id)

    try:
        if command == "!addaccount":
            if len(parts) < 2:
                return AccountCommandResult(True, False, _usage())
            label = parts[1].strip()
            upsert_broker_credentials(BrokerCredentialInput(account_label=label, user_id=user.user_id))
            return AccountCommandResult(True, True, f"✅ Account created: {label}")

        if command == "!myaccounts":
            accounts = get_user_accounts(user_id=user.user_id)
            if not accounts:
                return AccountCommandResult(True, True, "No broker accounts linked to your user yet.")
            lines = ["Your broker accounts:"]
            for a in accounts:
                active = "active" if a.is_active else "inactive"
                lines.append(f"- {a.label or a.account_id}: {a.broker}/{a.platform} ({active})")
            return AccountCommandResult(True, True, "\n".join(lines))

        if command == "!showaccount":
            if len(parts) < 2:
                return AccountCommandResult(True, False, _usage())
            label = parts[1].strip()
            return AccountCommandResult(True, True, safe_show_account(label, user_id=user.user_id))

        if len(parts) < 3:
            return AccountCommandResult(True, False, _usage())

        label = parts[1].strip()
        value = parts[2].strip()

        if command == "!setbroker":
            upsert_broker_credentials(BrokerCredentialInput(account_label=label, user_id=user.user_id, broker=value.lower()))
            return AccountCommandResult(True, True, f"✅ Broker updated for {label}: {value.lower()}")

        if command == "!setmt":
            platform = value.lower()
            if platform not in {"mt4", "mt5"}:
                return AccountCommandResult(True, False, "❌ Platform must be mt4 or mt5.")
            upsert_broker_credentials(BrokerCredentialInput(account_label=label, user_id=user.user_id, platform=platform))
            return AccountCommandResult(True, True, f"✅ Platform updated for {label}: {platform}")

        if command == "!setlogin":
            upsert_broker_credentials(BrokerCredentialInput(account_label=label, user_id=user.user_id, login=value))
            return AccountCommandResult(True, True, f"✅ Login updated for {label}")

        if command == "!setpassword":
            upsert_broker_credentials(BrokerCredentialInput(account_label=label, user_id=user.user_id, password=value))
            return AccountCommandResult(True, True, f"✅ Password updated for {label} (hidden)")

        if command == "!setserver":
            upsert_broker_credentials(BrokerCredentialInput(account_label=label, user_id=user.user_id, server=value))
            return AccountCommandResult(True, True, f"✅ Server updated for {label}")

    except Exception as exc:
        return AccountCommandResult(
            handled=True,
            ok=False,
            message=f"❌ Account command failed: {exc}",
        )

    return AccountCommandResult(handled=False, ok=False, message="")
