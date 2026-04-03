from __future__ import annotations

import os

from app.telegram.bot_client import load_bot_cfg, tg_post


def _first_int_from_csv(value: str) -> int:
    parts = [p.strip() for p in value.split(",") if p.strip()]
    if not parts:
        raise ValueError("No chat ids found")
    return int(parts[0])


def get_control_chat_id() -> int:
    """Resolve control chat id from env.

    Preferred:
      CONTROL_CHAT_ID

    Compatible fallbacks:
      TELEGRAM_CONTROL_CHAT_IDS (comma-separated; uses first)
      TELEGRAM_CONTROL_CHAT_ID

    Example:
        export CONTROL_CHAT_ID=-1001234567890
    """

    if "CONTROL_CHAT_ID" in os.environ:
        return int(os.environ["CONTROL_CHAT_ID"])

    control_ids = os.getenv("TELEGRAM_CONTROL_CHAT_IDS") or os.getenv("TELEGRAM_CONTROL_CHAT_ID")
    if control_ids:
        return _first_int_from_csv(control_ids)

    raise KeyError(
        "Missing CONTROL_CHAT_ID (or TELEGRAM_CONTROL_CHAT_IDS / TELEGRAM_CONTROL_CHAT_ID) in env"
    )


def send_control_alert(text: str) -> None:
    cfg = load_bot_cfg()
    chat_id = get_control_chat_id()

    payload = {
        "chat_id": chat_id,
        "text": f"🚨 ROUTING ALERT\n\n{text}",
        "parse_mode": "HTML",
        "disable_web_page_preview": True,
    }

    tg_post(cfg, "sendMessage", payload)
