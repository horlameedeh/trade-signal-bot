from __future__ import annotations

import os
from typing import Optional

from sqlalchemy import text


def _parse_int(s: str) -> int:
    s = (s or "").strip().replace("_", "")
    return int(s)


def _normalize_provider(provider: str) -> str:
    return (provider or "").strip().lower()


def _truthy_env(name: str, default: str = "0") -> bool:
    v = (os.getenv(name) or default).strip().lower()
    return v in {"1", "true", "yes", "y", "on"}


def _provider_exists(db, provider_code: str) -> bool:
    # Assumes providers table has a provider_code column (common in this project).
    # If schema differs, validation should remain opt-in.
    r = db.execute(
        text("SELECT 1 FROM providers WHERE provider_code = :p LIMIT 1"),
        {"p": provider_code},
    ).scalar()
    return bool(r)


def handle_admin_command(db, text_msg: str) -> str | None:
    """
    Handle control-chat admin commands.

    Supported:
      - !addchannel <provider> <channel_id>
      - !removechannel <provider> <channel_id>

    Notes:
      - Provider validation against `providers` table is optional (enable via ROUTING_VALIDATE_PROVIDER=1).
      - !removechannel accepts <provider> for readability, but removal is applied by chat_id (deterministic).
        If provided provider differs from existing mapping, reply includes a warning.

    Returns:
      HTML string reply if handled, else None.
    """
    msg = (text_msg or "").strip()
    if not msg.startswith("!"):
        return None

    parts = msg.split()
    cmd = parts[0].lower()

    if cmd not in {"!addchannel", "!removechannel"}:
        return None

    if len(parts) != 3:
        return (
            "<b>Usage</b>\n"
            "<code>!addchannel &lt;provider&gt; &lt;channel_id&gt;</code>\n"
            "<code>!removechannel &lt;provider&gt; &lt;channel_id&gt;</code>"
        )

    provider_code = _normalize_provider(parts[1])
    chat_id = _parse_int(parts[2])

    validate_provider = _truthy_env("ROUTING_VALIDATE_PROVIDER", "0")
    if validate_provider:
        try:
            if not _provider_exists(db, provider_code):
                return (
                    "❌ <b>Unknown provider</b>\n"
                    f"• provider: <code>{provider_code}</code>\n"
                    "\n"
                    "<i>Tip:</i> add/seed the provider in <code>providers</code> table, or disable validation with "
                    "<code>ROUTING_VALIDATE_PROVIDER=0</code>."
                )
        except Exception as e:
            # If providers schema differs, don't hard-break; instruct user.
            return (
                "❌ <b>Provider validation failed</b>\n"
                f"<code>{repr(e)}</code>\n\n"
                "Either seed/fix the <code>providers</code> table schema or disable validation with "
                "<code>ROUTING_VALIDATE_PROVIDER=0</code>."
            )

    if cmd == "!addchannel":
        db.execute(
            text(
                """
                INSERT INTO telegram_chats (chat_id, provider_code, updated_at)
                VALUES (:chat_id, :provider_code, now())
                ON CONFLICT (chat_id) DO UPDATE
                  SET provider_code = EXCLUDED.provider_code,
                      updated_at = now();
                """
            ),
            {"chat_id": chat_id, "provider_code": provider_code},
        )
        return (
            "✅ <b>Channel mapped</b>\n"
            f"• provider: <code>{provider_code}</code>\n"
            f"• chat_id: <code>{chat_id}</code>"
        )

    # !removechannel
    # Fetch current mapping for warning text
    current = (
        db.execute(
            text("SELECT provider_code FROM telegram_chats WHERE chat_id = :chat_id"),
            {"chat_id": chat_id},
        ).scalar()
    )

    db.execute(
        text(
            """
            UPDATE telegram_chats
            SET provider_code = NULL,
                updated_at = now()
            WHERE chat_id = :chat_id;
            """
        ),
        {"chat_id": chat_id},
    )

    warn = ""
    if current and (str(current).lower() != provider_code):
        warn = (
            "\n\n⚠️ <b>Note</b>: existing mapping was "
            f"<code>{str(current).lower()}</code> but you provided <code>{provider_code}</code>.\n"
            "Removal is applied by <b>chat_id</b> (deterministic)."
        )
    else:
        warn = (
            "\n\n<i>Note:</i> provider argument is accepted for readability; removal is applied by <b>chat_id</b>."
        )

    return (
        "✅ <b>Channel unmapped</b>\n"
        f"• provider: <code>{provider_code}</code>\n"
        f"• chat_id: <code>{chat_id}</code>"
        f"{warn}"
    )
