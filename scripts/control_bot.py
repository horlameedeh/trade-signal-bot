"""
Control chat bot (Bot API long polling).

Commands:
  !setcontrol  -> links current chat as control chat, stores chat_id in app_settings
  !health      -> basic status (DB ok, last_ingested)
  !testbuttons -> sends a test approval card with inline buttons

Callbacks:
  approve/reject/snooze -> recorded into control_actions table (queued)

Run:
  PYTHONPATH=. python scripts/control_bot.py
"""
from __future__ import annotations

import json
import time
from typing import Any, Dict, Optional

from sqlalchemy import text

from app.db.session import SessionLocal
from app.telegram.bot_client import load_bot_cfg, tg_get, tg_post


APP_SETTINGS_DDL = """
CREATE TABLE IF NOT EXISTS app_settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
"""

CONTROL_ACTIONS_DDL = """
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

def ensure_tables() -> None:
    with SessionLocal() as db:
        db.execute(text(APP_SETTINGS_DDL))
        db.execute(text(CONTROL_ACTIONS_DDL))
        db.commit()

def set_app_setting(key: str, value: str) -> None:
    with SessionLocal() as db:
        db.execute(
            text("""
            INSERT INTO app_settings (key, value, updated_at)
            VALUES (:k, :v, now())
            ON CONFLICT (key) DO UPDATE SET value=EXCLUDED.value, updated_at=now();
            """),
            {"k": key, "v": value},
        )
        db.commit()

def get_app_setting(key: str) -> Optional[str]:
    with SessionLocal() as db:
        row = db.execute(text("select value from app_settings where key=:k"), {"k": key}).fetchone()
    return row[0] if row else None

def upsert_control_chat_in_telegram_chats(chat_id: int, title: Optional[str] = None, username: Optional[str] = None) -> None:
    # Works with your existing telegram_chats schema from Milestone 0.
    with SessionLocal() as db:
        db.execute(
            text("""
            INSERT INTO telegram_chats (chat_id, title, username, is_control_chat, updated_at)
            VALUES (:chat_id, :title, :username, TRUE, now())
            ON CONFLICT (chat_id) DO UPDATE
              SET title=COALESCE(EXCLUDED.title, telegram_chats.title),
                  username=COALESCE(EXCLUDED.username, telegram_chats.username),
                  is_control_chat=TRUE,
                  updated_at=now();
            """),
            {"chat_id": chat_id, "title": title, "username": username},
        )
        db.commit()

def enqueue_action(telegram_user_id: Optional[int], control_chat_id: int, control_message_id: int, action: str, payload: Dict[str, Any]) -> None:
    with SessionLocal() as db:
        db.execute(
            text("""
            INSERT INTO control_actions (telegram_user_id, control_chat_id, control_message_id, action, payload, status)
            VALUES (:uid, :chat, :msg, :action, CAST(:payload AS jsonb), 'queued');
            """),
            {"uid": telegram_user_id, "chat": control_chat_id, "msg": control_message_id, "action": action, "payload": json.dumps(payload)},
        )
        db.commit()

def db_health() -> Dict[str, Any]:
    with SessionLocal() as db:
        db.execute(text("select 1")).fetchone()
        last = db.execute(text("select max(created_at) from telegram_messages")).scalar_one()
    return {"db": "ok", "last_ingested": str(last) if last else None}

def send_message(cfg, chat_id: int, text_msg: str) -> None:
    tg_post(cfg, "sendMessage", {"chat_id": chat_id, "text": text_msg})

def send_test_buttons(cfg, chat_id: int) -> None:
    keyboard = {
        "inline_keyboard": [
            [
                {"text": "✅ Approve", "callback_data": "approve"},
                {"text": "❌ Reject", "callback_data": "reject"},
                {"text": "😴 Snooze", "callback_data": "snooze"},
            ]
        ]
    }
    tg_post(
        cfg,
        "sendMessage",
        {
            "chat_id": chat_id,
            "text": "🧪 Test buttons: click one to verify callback → DB enqueue.",
            "reply_markup": keyboard,
        },
    )

def main() -> None:
    cfg = load_bot_cfg()
    ensure_tables()

    offset: Optional[int] = None
    print("🤖 control_bot.py polling started (Bot API). Ctrl+C to stop.")

    while True:
        try:
            params: Dict[str, Any] = {"timeout": 25}
            if offset is not None:
                params["offset"] = offset

            data = tg_get(cfg, "getUpdates", params=params)
            for upd in data.get("result", []):
                offset = upd["update_id"] + 1

                # Handle commands from messages
                if "message" in upd:
                    msg = upd["message"]
                    chat = msg.get("chat") or {}
                    chat_id = chat.get("id")
                    chat_title = chat.get("title")
                    chat_username = chat.get("username")
                    text_msg = (msg.get("text") or "").strip()

                    if not chat_id or not text_msg:
                        continue

                    if text_msg == "!setcontrol":
                        set_app_setting("control_chat_id", str(chat_id))
                        upsert_control_chat_in_telegram_chats(chat_id=int(chat_id), title=chat_title, username=chat_username)
                        send_message(cfg, chat_id, "✅ linked (control chat bound and saved)")
                        continue

                    if text_msg == "!health":
                        h = db_health()
                        control = get_app_setting("control_chat_id")
                        send_message(cfg, chat_id, f"✅ health\nDB: {h['db']}\nlast_ingested: {h['last_ingested']}\ncontrol_chat_id: {control}")
                        continue

                    if text_msg == "!testbuttons":
                        send_test_buttons(cfg, chat_id)
                        continue

                # Handle callback buttons
                if "callback_query" in upd:
                    cq = upd["callback_query"]
                    cq_id = cq["id"]
                    from_user = cq.get("from") or {}
                    uid = from_user.get("id")

                    msg = cq.get("message") or {}
                    chat = msg.get("chat") or {}
                    chat_id = chat.get("id")
                    message_id = msg.get("message_id")
                    action = cq.get("data")

                    # Always answer callback so Telegram UI stops spinning
                    try:
                        tg_post(cfg, "answerCallbackQuery", {"callback_query_id": cq_id})
                    except Exception:
                        pass

                    # Only accept callbacks from the linked control chat (if set),
                    # otherwise accept from any chat (useful for first-time testing).
                    linked = get_app_setting("control_chat_id")
                    if linked and str(chat_id) != linked:
                        continue

                    if chat_id and message_id and action:
                        enqueue_action(
                            telegram_user_id=uid,
                            control_chat_id=int(chat_id),
                            control_message_id=int(message_id),
                            action=str(action),
                            payload={"update_id": upd.get("update_id"), "source": "callback"},
                        )
                        send_message(cfg, int(chat_id), f"✅ Callback received: {action} (enqueued)")

            time.sleep(0.5)

        except KeyboardInterrupt:
            print("\nStopped.")
            return
        except Exception as e:
            print("Error:", repr(e))
            time.sleep(2.0)

if __name__ == "__main__":
    main()
