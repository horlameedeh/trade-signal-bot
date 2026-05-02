import uuid

import pytest
from sqlalchemy import text

from app.db.session import SessionLocal
from app.telegram.ingestion_router import route_ingested_messages_dry_run


pytestmark = pytest.mark.integration


def _seed_active_route(*, provider: str = "fredtrading", broker: str = "ftmo", equity_start: str = "10000") -> None:
    account_id = str(uuid.uuid4())

    with SessionLocal() as db:
        db.execute(
            text(
                """
                INSERT INTO broker_accounts (
                  account_id, broker, platform, kind, label,
                  allowed_providers, equity_start, is_active
                )
                VALUES (
                  CAST(:account_id AS uuid),
                  :broker,
                  'mt5',
                  'personal_live',
                  :label,
                  ARRAY[]::provider_code[],
                  :equity_start,
                  true
                )
                """
            ),
            {
                "account_id": account_id,
                "broker": broker,
                "label": f"ingestion-router-{account_id}",
                "equity_start": equity_start,
            },
        )

        db.execute(
            text(
                """
                UPDATE provider_account_routes
                SET is_active = false
                WHERE provider_code = :provider
                """
            ),
            {"provider": provider},
        )

        db.execute(
            text(
                """
                INSERT INTO provider_account_routes (provider_code, broker_account_id, is_active)
                VALUES (:provider, CAST(:account_id AS uuid), true)
                """
            ),
            {"provider": provider, "account_id": account_id},
        )
        db.commit()


def _insert_msg(chat_id: int, message_id: int, text_value: str, provider_code: str | None = None):
    with SessionLocal() as db:
        db.execute(
            text(
                """
                INSERT INTO telegram_chats (chat_id, provider_code)
                VALUES (:chat_id, CAST(:provider_code AS provider_code))
                ON CONFLICT (chat_id) DO UPDATE
                SET provider_code = COALESCE(EXCLUDED.provider_code, telegram_chats.provider_code)
                """
            ),
            {"chat_id": chat_id, "provider_code": provider_code},
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

    _seed_active_route(provider="fredtrading")

    _insert_msg(
        chat_id,
        message_id,
        "BUY XAUUSD\nENTRY 4639\nSL 4633\nTP1 4645",
        provider_code="fredtrading",
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

    assert status == "planned"


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