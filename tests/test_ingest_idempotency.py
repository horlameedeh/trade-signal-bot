from datetime import datetime, timezone

from sqlalchemy import text

from app.db.session import SessionLocal
from app.ingest.storage import upsert_chat, upsert_message_new_or_seen


def test_unique_chat_id_message_id_idempotent():
    chat_id = -1001234567890
    message_id = 42

    upsert_chat(chat_id=chat_id, chat_type="channel", title="Test", username="test", is_control=False)

    payload = {"id": message_id, "message": "hello", "date": datetime.now(timezone.utc).isoformat()}

    upsert_message_new_or_seen(
        chat_id=chat_id,
        message_id=message_id,
        sender_id=111,
        date=datetime.now(timezone.utc),
        message_text="hello",
        raw_json=payload,
    )

    # retry same ingest should not duplicate
    upsert_message_new_or_seen(
        chat_id=chat_id,
        message_id=message_id,
        sender_id=111,
        date=datetime.now(timezone.utc),
        message_text="hello",
        raw_json=payload,
    )

    with SessionLocal() as db:
        n = db.execute(
            text("select count(*) from telegram_messages where chat_id=:c and message_id=:m"),
            {"c": chat_id, "m": message_id},
        ).scalar_one()

    assert n == 1
