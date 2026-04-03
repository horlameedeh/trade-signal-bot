"""
Minimal Control Chat Bot (Bot API long polling).

Goals:
- Post a test approval card with inline keyboard buttons.
- Handle callback_query events.
- On callback: write to DB and enqueue an action (without executing anything).

This bot creates a small table if missing:

  control_actions(
    id uuid primary key default gen_random_uuid(),
    created_at timestamptz default now(),
    telegram_user_id bigint,
    control_chat_id bigint,
    control_message_id bigint,
    action text,
    payload jsonb,
    status text default 'queued'
  )

Env:
  TELEGRAM_BOT_TOKEN=...
  TELEGRAM_CONTROL_CHAT_IDS=-5211338635         (comma-separated ok; uses first)
  DATABASE_URL=...                               (already in your project)

Run:
  PYTHONPATH=. python -m app.telegram.control_bot

Send test card:
  PYTHONPATH=. python -m app.telegram.control_bot --send-test-card
"""
from __future__ import annotations

import argparse
import json
import os
import time

def _parse_admin_ids(value: str | None) -> set[int]:
    if not value:
        return set()
    out: set[int] = set()
    for p in value.split(","):
        p = p.strip()
        if not p:
            continue
        try:
            out.add(int(p))
        except Exception:
            continue
    return out


def is_admin_user(user_id: int | None) -> bool:
    # If TELEGRAM_ADMIN_USER_IDS is not set, allow (backwards compatible).
    admin_csv = os.getenv("TELEGRAM_ADMIN_USER_IDS", "").strip()
    admins = _parse_admin_ids(admin_csv)
    if not admins:
        return True
    return bool(user_id) and int(user_id) in admins

from typing import Any, Dict, Optional

from sqlalchemy import text

from app.control.health import build_health_text
from app.db.session import SessionLocal
from app.routing.showrouting import build_showrouting_text
from app.routing.admin_commands import handle_admin_command
from app.services.approval_callbacks import handle_approval_callback
from app.telegram.bot_client import BotCfg, load_bot_cfg, tg_get, tg_post


def _parse_int_set(value: str | None) -> set[int]:
    if not value:
        return set()
    out: set[int] = set()
    for part in value.split(","):
        part = part.strip()
        if not part:
            continue
        try:
            out.add(int(part))
        except ValueError:
            continue
    return out


def get_admin_user_ids() -> set[int]:
    """Admin allowlist for control bot commands.

    Configure via env:
      CONTROL_ADMIN_USER_IDS="123,456"   (preferred)
    Fallback:
      ROUTING_ADMIN_USER_IDS="123,456"

    If neither is set, returns empty set and commands are not gated.
    """

    return _parse_int_set(os.getenv("CONTROL_ADMIN_USER_IDS") or os.getenv("ROUTING_ADMIN_USER_IDS"))


def _first_int_from_csv(value: str) -> int:
    parts = [p.strip() for p in value.split(",") if p.strip()]
    if not parts:
        raise ValueError("No chat ids found")
    return int(parts[0])


def get_control_chat_id() -> int:
    control_ids = os.getenv("TELEGRAM_CONTROL_CHAT_IDS") or os.getenv("TELEGRAM_CONTROL_CHAT_ID")
    if not control_ids:
        raise SystemExit("Missing TELEGRAM_CONTROL_CHAT_IDS (or TELEGRAM_CONTROL_CHAT_ID) in env")
    return _first_int_from_csv(control_ids)


def load_cfg() -> tuple[BotCfg, int]:
    cfg = load_bot_cfg()
    return cfg, get_control_chat_id()


def ensure_control_actions_table() -> None:
    ddl = """
    CREATE TABLE IF NOT EXISTS control_actions (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
      telegram_user_id BIGINT,
      control_chat_id BIGINT,
      control_message_id BIGINT,
      action TEXT NOT NULL,
      payload JSONB NOT NULL DEFAULT '{}'::jsonb,
      status TEXT NOT NULL DEFAULT 'queued'
    );
    CREATE INDEX IF NOT EXISTS idx_control_actions_status_time ON control_actions(status, created_at DESC);
    """
    with SessionLocal() as db:
        db.execute(text(ddl))
        db.commit()


def send_test_card(cfg: BotCfg, control_chat_id: int) -> None:
    # Callback data must be <= 64 bytes. Keep it compact.
    # We'll encode action only; we will enqueue into DB upon callback.
    keyboard = {
        "inline_keyboard": [
            [
                {"text": "✅ Approve", "callback_data": "approve"},
                {"text": "❌ Reject", "callback_data": "reject"},
                {"text": "😴 Snooze", "callback_data": "snooze"},
            ]
        ]
    }

    msg = (
        "🧪 *Test Approval Card*\n\n"
        "This is a Milestone 1 wiring test.\n"
        "Press a button to verify callback handling + DB enqueue."
    )

    data = tg_post(
        cfg,
        "sendMessage",
        {
            "chat_id": control_chat_id,
            "text": msg,
            "parse_mode": "Markdown",
            "reply_markup": keyboard,
        },
    )
    message_id = data["result"]["message_id"]
    print(f"✅ Sent test card to control chat {control_chat_id} message_id={message_id}")


def enqueue_action(
    *,
    telegram_user_id: Optional[int],
    control_chat_id: int,
    control_message_id: int,
    action: str,
    payload: Dict[str, Any],
) -> None:
    with SessionLocal() as db:
        db.execute(
            text(
                """
                INSERT INTO control_actions (telegram_user_id, control_chat_id, control_message_id, action, payload, status)
                VALUES (:uid, :chat, :msg, :action, CAST(:payload AS jsonb), 'queued');
                """
            ),
            dict(
                uid=telegram_user_id,
                chat=control_chat_id,
                msg=control_message_id,
                action=action,
                payload=json.dumps(payload),
            ),
        )
        db.commit()


def poll_updates(cfg: BotCfg, control_chat_id: int, *, sleep_s: float = 1.0) -> None:
    offset: Optional[int] = None
    print("🤖 Control bot polling started. Press Ctrl+C to stop.")

    while True:
        try:
            params: Dict[str, Any] = {"timeout": 25}
            if offset is not None:
                params["offset"] = offset

            data = tg_get(cfg, "getUpdates", params)
            for upd in data.get("result", []):
                offset = upd["update_id"] + 1

                if "callback_query" in upd:
                    cq = upd["callback_query"]
                    cq_id = cq["id"]
                    from_user = cq.get("from", {}) or {}
                    uid = from_user.get("id")

                    msg = cq.get("message") or {}
                    chat = msg.get("chat") or {}
                    chat_id = chat.get("id")
                    message_id = msg.get("message_id")
                    action = cq.get("data")  # approve/reject/snooze

                    # Always answer callback to remove "loading" UI
                    try:
                        tg_post(cfg, "answerCallbackQuery", {"callback_query_id": cq_id})
                    except Exception:
                        pass

                    # Only accept callbacks from the configured control chat
                    if chat_id != control_chat_id:
                        continue

                    if isinstance(action, str) and action.startswith("approve:"):
                        result = handle_approval_callback(
                            callback_data=action,
                            telegram_user_id=uid,
                            control_chat_id=chat_id,
                            control_message_id=message_id,
                        )
                        tg_post(
                            cfg,
                            "sendMessage",
                            {
                                "chat_id": control_chat_id,
                                "text": (
                                    f"✅ Approval callback handled\n"
                                    f"action={result.action.value}\n"
                                    f"created={result.control_action_created}\n"
                                    f"reason={result.reason}"
                                ),
                            },
                        )
                        print(f"Handled approval callback action={action} uid={uid} msg_id={message_id}")
                        continue

                    ensure_control_actions_table()
                    enqueue_action(
                        telegram_user_id=uid,
                        control_chat_id=chat_id,
                        control_message_id=message_id,
                        action=action,
                        payload={"source": "test_card", "update_id": upd.get("update_id")},
                    )

                    # Confirm to control chat (no sensitive info)
                    tg_post(
                        cfg,
                        "sendMessage",
                        {
                            "chat_id": control_chat_id,
                            "text": f"✅ Callback received: *{action}* (enqueued)",
                            "parse_mode": "Markdown",
                        },
                    )
                    print(f"Enqueued action={action} from uid={uid} msg_id={message_id}")
                    continue

                # --- handle incoming text commands in control chat ---
                msg = upd.get("message") or {}
                chat = msg.get("chat") or {}
                chat_id = chat.get("id")
                if chat_id != control_chat_id:
                    continue

                from_user = msg.get("from") or {}
                uid = from_user.get("id")
                admin_user_ids = get_admin_user_ids()
                if admin_user_ids and (uid not in admin_user_ids):
                    continue

                text_msg = (msg.get("text") or "").strip()
                from_user = msg.get("from") or {}
                uid = from_user.get("id")

                # Admin gating: only approved Telegram user IDs can run admin commands.
                # If TELEGRAM_ADMIN_USER_IDS is unset/empty, all users are allowed (backwards compatible).
                if text_msg:
                    cmd = text_msg.strip().lower()
                    # Allow !whoami for everyone (needed to discover user_id)
                    if cmd == "!whoami":
                        pass
                    # Gate admin commands
                    elif cmd.startswith("!") or cmd in {"/health"}:
                        if not is_admin_user(uid):
                            tg_post(
                                cfg,
                                "sendMessage",
                                {
                                    "chat_id": control_chat_id,
                                    "text": "⛔ Not authorized.",
                                    "parse_mode": "HTML",
                                    "disable_web_page_preview": True,
                                },
                            )
                            continue

                    if not is_admin_user(uid):
                        tg_post(
                            cfg,
                            "sendMessage",
                            {
                                "chat_id": control_chat_id,
                                "text": "⛔ Not authorized.",
                                "parse_mode": "HTML",
                                "disable_web_page_preview": True,
                            },
                        )
                        continue

                if text_msg.lower() == "!whoami":
                    from_user = msg.get("from") or {}
                    uid = from_user.get("id")
                    tg_post(
                        cfg,
                        "sendMessage",
                        {
                            "chat_id": control_chat_id,
                            "text": f"👤 Your Telegram user_id: <code>{uid}</code>",
                            "parse_mode": "HTML",
                        },
                    )
                    continue

                if text_msg.lower() == "!showrouting":
                    reply = build_showrouting_text()
                    tg_post(
                        cfg,
                        "sendMessage",
                        {
                            "chat_id": control_chat_id,
                            "text": reply,
                            "parse_mode": "HTML",
                            "disable_web_page_preview": True,
                        },
                    )
                    continue

                if text_msg.strip().lower() in {"/health", "!health"}:
                    reply = build_health_text()
                    tg_post(
                        cfg,
                        "sendMessage",
                        {
                            "chat_id": control_chat_id,
                            "text": reply,
                            "parse_mode": "HTML",
                            "disable_web_page_preview": True,
                        },
                    )
                    continue

                # --- handle admin routing commands (!addchannel / !removechannel) ---
                try:
                    with SessionLocal() as db:
                        reply = handle_admin_command(db, text_msg)
                        if reply:
                            db.commit()
                            tg_post(
                                cfg,
                                "sendMessage",
                                {
                                    "chat_id": control_chat_id,
                                    "text": reply,
                                    "parse_mode": "HTML",
                                    "disable_web_page_preview": True,
                                },
                            )
                            continue
                except Exception as e:
                    tg_post(
                        cfg,
                        "sendMessage",
                        {
                            "chat_id": control_chat_id,
                            "text": f"❌ Admin command failed: <code>{repr(e)}</code>",
                            "parse_mode": "HTML",
                            "disable_web_page_preview": True,
                        },
                    )
                    continue

        except KeyboardInterrupt:
            print("\nStopped.")
            return
        except Exception as e:
            print("Error in poll loop:", repr(e))
            time.sleep(2.0)


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--send-test-card", action="store_true", help="Send a test approval card to control chat")
    args = p.parse_args()

    cfg, control_chat_id = load_cfg()
    ensure_control_actions_table()

    if args.send_test_card:
        send_test_card(cfg, control_chat_id)
        return

    poll_updates(cfg, control_chat_id)


if __name__ == "__main__":
    main()
