import uuid

import pytest
from sqlalchemy import text

from app.db.session import SessionLocal
from app.parsing.service import parse_and_persist_message


pytestmark = pytest.mark.integration


@pytest.fixture
def db_session():
    with SessionLocal() as db:
        try:
            yield db
        finally:
            db.rollback()


def _seed_broker_account(db_session, *, broker: str, platform: str = "mt5", kind: str = "personal_live", label: str = "sim") -> str:
    account_id = str(uuid.uuid4())
    db_session.execute(
        text(
            """
            INSERT INTO broker_accounts (account_id, broker, platform, kind, label, allowed_providers)
            VALUES (:account_id, :broker, :platform, :kind, :label, ARRAY[]::provider_code[])
            """
        ),
        {
            "account_id": account_id,
            "broker": broker,
            "platform": platform,
            "kind": kind,
            "label": f"{label}-{broker}",
        },
    )
    return account_id


def _seed_provider_route(db_session, *, provider_code: str, broker_account_id: str):
    # path 2 schema: history + one active
    db_session.execute(
        text(
            """
            UPDATE provider_account_routes
            SET is_active=false, updated_at=now()
            WHERE provider_code = :provider_code
            """
        ),
        {"provider_code": provider_code},
    )
    db_session.execute(
        text(
            """
            INSERT INTO provider_account_routes (provider_code, broker_account_id, is_active)
            VALUES (:provider_code, CAST(:broker_account_id AS uuid), true)
            ON CONFLICT (provider_code, broker_account_id)
            DO UPDATE SET is_active=true, updated_at=now()
            """
        ),
        {"provider_code": provider_code, "broker_account_id": broker_account_id},
    )


def _seed_message(db_session, *, chat_id: int, provider_code: str, message_id: int, text_value: str) -> str:
    db_session.execute(
        text(
            """
            INSERT INTO telegram_chats (chat_id, provider_code)
            VALUES (:chat_id, :provider_code)
            ON CONFLICT (chat_id)
            DO UPDATE SET provider_code = EXCLUDED.provider_code
            """
        ),
        {"chat_id": chat_id, "provider_code": provider_code},
    )

    existing = db_session.execute(
        text(
            """
            SELECT msg_pk
            FROM telegram_messages
            WHERE chat_id = :chat_id AND message_id = :message_id
            LIMIT 1
            """
        ),
        {"chat_id": chat_id, "message_id": message_id},
    ).scalar()

    if existing:
        msg_pk = str(existing)
    else:
        msg_pk = str(uuid.uuid4())
        db_session.execute(
            text(
                """
                INSERT INTO telegram_messages (msg_pk, chat_id, message_id, text, raw_json)
                VALUES (CAST(:msg_pk AS uuid), :chat_id, :message_id, :text, '{}'::jsonb)
                """
            ),
            {
                "msg_pk": msg_pk,
                "chat_id": chat_id,
                "message_id": message_id,
                "text": text_value,
            },
        )
    db_session.commit()
    return msg_pk


def test_service_parses_and_persists_new_trade(db_session):
    account_id = _seed_broker_account(db_session, broker="ftmo", label="svc")
    _seed_provider_route(db_session, provider_code="fredtrading", broker_account_id=account_id)

    msg_pk = _seed_message(
        db_session,
        chat_id=-1001239815745,
        provider_code="fredtrading",
        message_id=910001,
        text_value="BUY GOLD now\nSL 2010\nTP 2030 2040",
    )

    db_session.commit()

    result = parse_and_persist_message(msg_pk)

    assert result.persisted is True
    assert result.provider_code == "fredtrading"
    assert result.parsed is not None
    assert result.parsed.message_type.value == "NEW_TRADE"

    row = db_session.execute(
        text(
            """
            SELECT provider, source_msg_pk, symbol_canonical, side, order_type
            FROM trade_intents
            WHERE source_msg_pk = CAST(:msg_pk AS uuid)
            """
        ),
        {"msg_pk": msg_pk},
    ).mappings().first()

    assert row is not None
    assert row["provider"] == "fredtrading"
    assert str(row["source_msg_pk"]) == msg_pk
    assert row["symbol_canonical"] == "XAUUSD"
    assert row["side"] == "buy"
    assert row["order_type"] == "market"


def test_service_is_idempotent_for_same_msg_pk(db_session):
    account_id = _seed_broker_account(db_session, broker="ftmo", label="svc2")
    _seed_provider_route(db_session, provider_code="fredtrading", broker_account_id=account_id)

    msg_pk = _seed_message(
        db_session,
        chat_id=-1001239815745,
        provider_code="fredtrading",
        message_id=910002,
        text_value="BUY GOLD now\nSL 2010\nTP 2030",
    )
    db_session.commit()

    r1 = parse_and_persist_message(msg_pk)
    r2 = parse_and_persist_message(msg_pk)

    assert r1.persisted is True
    assert r2.persisted is True

    count = db_session.execute(
        text("SELECT COUNT(*) FROM trade_intents WHERE source_msg_pk = CAST(:msg_pk AS uuid)"),
        {"msg_pk": msg_pk},
    ).scalar()

    assert count == 1


def test_service_parses_and_persists_update(db_session):
    account_id = _seed_broker_account(db_session, broker="fundednext", label="svc3")
    _seed_provider_route(db_session, provider_code="mubeen", broker_account_id=account_id)

    msg_pk = _seed_message(
        db_session,
        chat_id=-1002298510219,
        provider_code="mubeen",
        message_id=910003,
        text_value="BTC update: TP1 to 53000",
    )
    db_session.commit()

    result = parse_and_persist_message(msg_pk)

    assert result.persisted is True
    assert result.parsed is not None
    assert result.parsed.message_type.value == "UPDATE"

    row = db_session.execute(
        text(
            """
            SELECT provider, source_msg_pk, kind, symbol_canonical
            FROM trade_updates
            WHERE source_msg_pk = CAST(:msg_pk AS uuid)
            """
        ),
        {"msg_pk": msg_pk},
    ).mappings().first()

    assert row is not None
    assert row["provider"] == "mubeen"
    assert row["kind"] == "move_tp"
    assert row["symbol_canonical"] == "BTCUSD"
