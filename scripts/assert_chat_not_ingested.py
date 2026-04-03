"""
Assert a chat_id is NOT being ingested (no rows in telegram_chats or telegram_messages).

Usage:
  PYTHONPATH=. python scripts/assert_chat_not_ingested.py --chat-id -1001234567890
"""
import argparse
from sqlalchemy import text
from app.db.session import SessionLocal

def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--chat-id", type=int, required=True)
    args = p.parse_args()

    chat_id = args.chat_id

    with SessionLocal() as db:
        chat_row = db.execute(
            text("select chat_id from telegram_chats where chat_id=:c"),
            {"c": chat_id},
        ).fetchone()

        msg_count = db.execute(
            text("select count(*) from telegram_messages where chat_id=:c"),
            {"c": chat_id},
        ).scalar_one()

    if chat_row is None and msg_count == 0:
        print(f"✅ PASS: chat_id {chat_id} not present in telegram_chats and has 0 messages.")
        return

    print(f"❌ FAIL: chat_id {chat_id} appears in DB.")
    print(f"   telegram_chats row exists: {chat_row is not None}")
    print(f"   telegram_messages count:  {msg_count}")
    raise SystemExit(2)

if __name__ == "__main__":
    main()
