import uuid

import pytest
from sqlalchemy import text

from app.db.session import SessionLocal
from app.services.trade_writer import create_trade_family_and_legs


pytestmark = pytest.mark.integration


@pytest.fixture
def db_session():
    with SessionLocal() as db:
        try:
            yield db
        finally:
            db.rollback()


def _seed_account(db_session, *, broker: str, platform: str, equity_start: str) -> str:
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
              :platform,
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
            "platform": platform,
            "label": f"seed-{broker}-{platform}-{equity_start}",
            "equity_start": equity_start,
        },
    )
    return account_id


def _seed_intent_plan(db_session, *, provider: str, broker: str, platform: str, equity_start: str, symbol: str) -> str:
    chat_id = -1001239815745
    source_msg_pk = str(uuid.uuid4())
    source_message_id = 910000 + (uuid.UUID(source_msg_pk).int % 99999)
    intent_id = str(uuid.uuid4())
    account_id = _seed_account(db_session, broker=broker, platform=platform, equity_start=equity_start)

    db_session.execute(
        text(
            """
            INSERT INTO telegram_chats (chat_id, provider_code)
            VALUES (:chat_id, :provider)
            ON CONFLICT (chat_id) DO UPDATE SET provider_code = EXCLUDED.provider_code
            """
        ),
        {"chat_id": chat_id, "provider": provider},
    )

    db_session.execute(
        text(
            """
            INSERT INTO telegram_messages (msg_pk, chat_id, message_id, text, raw_json)
            VALUES (CAST(:pk AS uuid), :chat_id, :source_message_id, 'seed', '{}'::jsonb)
            ON CONFLICT (chat_id, message_id) DO NOTHING
            """
        ),
        {"pk": source_msg_pk, "chat_id": chat_id, "source_message_id": source_message_id},
    )

    db_session.execute(
        text(
            """
            INSERT INTO symbols (canonical, asset_class)
            VALUES (:symbol, 'unknown')
            ON CONFLICT (canonical) DO NOTHING
            """
        ),
        {"symbol": symbol},
    )

    db_session.execute(
        text(
            """
            INSERT INTO trade_intents (
              intent_id, provider, chat_id, source_msg_pk, source_message_id, dedupe_hash,
              parse_confidence, symbol_canonical, symbol_raw, side, order_type,
              entry_price, sl_price, tp_prices, has_runner, risk_tag,
              is_scalp, is_swing, is_unofficial, reenter_tag, instructions, meta
            )
            VALUES (
              CAST(:intent_id AS uuid), :provider, :chat_id, CAST(:pk AS uuid), :source_message_id, :dedupe_hash,
              0.950, :symbol, :symbol, 'buy', 'market',
              2025, 2010, ARRAY[2030,2040,2050,2060]::numeric(18,10)[], false, 'normal',
              false, false, false, false, 'seed', '{}'::jsonb
            )
            """
        ),
        {
            "intent_id": intent_id,
            "provider": provider,
            "chat_id": chat_id,
            "pk": source_msg_pk,
            "source_message_id": source_message_id,
            "dedupe_hash": f"seed-{source_msg_pk}",
            "symbol": symbol,
        },
    )

    db_session.execute(
        text(
            """
            INSERT INTO trade_plans (
              intent_id, account_id, policy_outcome, requires_approval, policy_reasons
            )
            VALUES (
              CAST(:intent_id AS uuid), CAST(:account_id AS uuid), 'allow'::policy_outcome, false, ARRAY['seed']::text[]
            )
            """
        ),
        {"intent_id": intent_id, "account_id": account_id},
    )

    db_session.commit()
    return source_msg_pk


def test_trade_writer_stores_resolved_ftmo_symbol(db_session):
    source_msg_pk = _seed_intent_plan(
        db_session,
        provider="fredtrading",
        broker="ftmo",
        platform="mt5",
        equity_start="10000",
        symbol="DJ30",
    )

    result = create_trade_family_and_legs(source_msg_pk=source_msg_pk)

    broker_symbol = db_session.execute(
        text("SELECT broker_symbol FROM trade_families WHERE family_id = CAST(:family_id AS uuid)"),
        {"family_id": result.family_id},
    ).scalar()

    assert broker_symbol == "US30.cash"


def test_trade_writer_stores_resolved_vantage_symbol(db_session):
    source_msg_pk = _seed_intent_plan(
        db_session,
        provider="fredtrading",
        broker="vantage",
        platform="mt5",
        equity_start="1000",
        symbol="XAUUSD",
    )

    result = create_trade_family_and_legs(source_msg_pk=source_msg_pk)

    broker_symbol = db_session.execute(
        text("SELECT broker_symbol FROM trade_families WHERE family_id = CAST(:family_id AS uuid)"),
        {"family_id": result.family_id},
    ).scalar()

    assert broker_symbol == "GOLD"


def test_missing_symbol_mapping_blocks_trade_writer(db_session):
    source_msg_pk = _seed_intent_plan(
        db_session,
        provider="fredtrading",
        broker="ftmo",
        platform="mt5",
        equity_start="10000",
        symbol="UNKNOWNXYZ",
    )

    with pytest.raises(RuntimeError) as e:
        create_trade_family_and_legs(source_msg_pk=source_msg_pk)

    assert "Symbol mapping blocked trade creation" in str(e.value)
