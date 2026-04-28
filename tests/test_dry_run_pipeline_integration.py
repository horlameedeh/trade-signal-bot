import uuid

import pytest
from sqlalchemy import text

from app.db.session import SessionLocal
from app.services.dry_run_pipeline import process_message_dry_run


pytestmark = pytest.mark.integration


@pytest.fixture
def db_session():
    with SessionLocal() as db:
        try:
            yield db
        finally:
            db.rollback()


def _seed_active_route(db_session, *, provider: str = "fredtrading", broker: str = "ftmo", equity_start: str = "10000") -> None:
    account_id = str(uuid.uuid4())
    db_session.execute(
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
            "label": f"dry-run-{broker}-{equity_start}",
            "equity_start": equity_start,
        },
    )

    db_session.execute(
        text(
            """
            UPDATE provider_account_routes
            SET is_active = false
            WHERE provider_code = :provider
            """
        ),
        {"provider": provider},
    )

    db_session.execute(
        text(
            """
            INSERT INTO provider_account_routes (provider_code, broker_account_id, is_active)
            VALUES (:provider, CAST(:account_id AS uuid), true)
            ON CONFLICT (provider_code, broker_account_id)
            DO UPDATE SET is_active = true
            """
        ),
        {"provider": provider, "account_id": account_id},
    )


def _seed_message(db_session) -> tuple[int, int]:
    chat_id = -1001239815745
    message_id = 890000 + (uuid.uuid4().int % 99999)
    msg_pk = str(uuid.uuid4())

    db_session.execute(
        text(
            """
            INSERT INTO telegram_chats (chat_id, provider_code)
            VALUES (:chat_id, 'fredtrading')
            ON CONFLICT (chat_id) DO UPDATE SET provider_code='fredtrading'
            """
        ),
        {"chat_id": chat_id},
    )

    db_session.execute(
        text(
            """
            INSERT INTO telegram_messages (msg_pk, chat_id, message_id, text, raw_json)
            VALUES (
              CAST(:msg_pk AS uuid),
              :chat_id,
              :message_id,
              :txt,
              '{}'::jsonb
            )
            """
        ),
        {
            "msg_pk": msg_pk,
            "chat_id": chat_id,
            "message_id": message_id,
            "txt": """
XAUUSD Buy now
Enter 4812
SL 4785
TP1 4817
TP2 4822
TP3 4830
TP4 4870
""",
        },
    )

    db_session.commit()
    return chat_id, message_id


def test_dry_run_pipeline_creates_intent_family_and_mock_executions(db_session):
    _seed_active_route(db_session)
    chat_id, message_id = _seed_message(db_session)

    result = process_message_dry_run(chat_id=chat_id, message_id=message_id)

    assert result.reason == "ok"
    assert result.intent_created is True
    assert result.family_created is True
    assert result.mock_executions_created == 4


def test_dry_run_pipeline_is_idempotent_on_same_message(db_session):
    _seed_active_route(db_session)
    chat_id, message_id = _seed_message(db_session)

    first = process_message_dry_run(chat_id=chat_id, message_id=message_id)
    second = process_message_dry_run(chat_id=chat_id, message_id=message_id)

    assert first.reason == "ok"
    assert second.reason == "ok"

    assert first.intent_created is True
    assert first.family_created is True
    assert first.mock_executions_created == 4

    assert second.intent_created is False
    assert second.family_created is False
    assert second.mock_executions_created == 0


def test_dry_run_pipeline_non_trade_is_noop(db_session):
    chat_id = -1001239815745
    message_id = 880000 + (uuid.uuid4().int % 99999)

    db_session.execute(
        text(
            """
            INSERT INTO telegram_chats (chat_id, provider_code)
            VALUES (:chat_id, 'fredtrading')
            ON CONFLICT (chat_id) DO UPDATE SET provider_code='fredtrading'
            """
        ),
        {"chat_id": chat_id},
    )

    db_session.execute(
        text(
            """
            INSERT INTO telegram_messages (msg_pk, chat_id, message_id, text, raw_json)
            VALUES (gen_random_uuid(), :chat_id, :message_id, 'hello info only', '{}'::jsonb)
            """
        ),
        {"chat_id": chat_id, "message_id": message_id},
    )
    db_session.commit()

    result = process_message_dry_run(chat_id=chat_id, message_id=message_id)

    assert result.reason == "not_new_trade"
    assert result.intent_created is False
    assert result.family_created is False
    assert result.mock_executions_created == 0
