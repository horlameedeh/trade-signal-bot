import pytest
from sqlalchemy import text

from app.db.session import SessionLocal
from app.telegram.ingestion_router import route_ingested_messages_dry_run


pytestmark = pytest.mark.integration


def _insert_msg(chat_id: int, message_id: int, text_value: str):
    with SessionLocal() as db:
        db.execute(
            text(
                """
                INSERT INTO telegram_chats (chat_id)
                VALUES (:chat_id)
                ON CONFLICT (chat_id) DO NOTHING
                """
            ),
            {"chat_id": chat_id},
        )
        db.execute(
            text(
                """
                DELETE FROM telegram_messages
                WHERE chat_id = :chat_id AND message_id = :message_id
                """
            ),
            {"chat_id": chat_id, "message_id": message_id},
        )
        db.execute(
            text(
                """
                INSERT INTO telegram_messages (chat_id, message_id, text, raw_json)
                VALUES (
                  :chat_id,
                  :message_id,
                  :text_value,
                  jsonb_build_object('source', 'telethon_ingestion', 'dry_run', true)
                )
                """
            ),
            {
                "chat_id": chat_id,
                "message_id": message_id,
                "text_value": text_value,
            },
        )
        db.commit()


def test_ingestion_router_marks_trade_candidates():
    chat_id = -100777999001
    message_id = 9001

    _insert_msg(
        chat_id,
        message_id,
        "BUY XAUUSD\nENTRY 4639\nSL 4633\nTP1 4645",
    )

    result = route_ingested_messages_dry_run(limit=10000)

    assert result.messages_seen >= 1
    assert result.routed >= 1

    with SessionLocal() as db:
        status = db.execute(
            text(
                """
                SELECT raw_json->>'ingestion_route_status'
                FROM telegram_messages
                WHERE chat_id = :chat_id AND message_id = :message_id
                """
            ),
            {"chat_id": chat_id, "message_id": message_id},
        ).scalar()

    assert status == "candidate"


def test_ingestion_router_ignores_non_trade_messages():
    chat_id = -100777999002
    message_id = 9002

    _insert_msg(chat_id, message_id, "Good morning everyone")

    result = route_ingested_messages_dry_run(limit=10000)

    assert result.messages_seen >= 1
    assert result.ignored >= 1

    with SessionLocal() as db:
        status = db.execute(
            text(
                """
                SELECT raw_json->>'ingestion_route_status'
                FROM telegram_messages
                WHERE chat_id = :chat_id AND message_id = :message_id
                """
            ),
            {"chat_id": chat_id, "message_id": message_id},
        ).scalar()

    assert status == "ignored"