import uuid
from decimal import Decimal

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


def _seed_intent_plan(db_session, *, provider: str, broker: str, platform: str, equity_start: str, symbol: str, order_type: str = "market", entry_price: str = "4662") -> str:
    chat_id = -1001239815745
    source_msg_pk = str(uuid.uuid4())
    source_message_id = 920000 + (uuid.UUID(source_msg_pk).int % 99999)
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
            INSERT INTO trade_intents (
              intent_id, provider, chat_id, source_msg_pk, source_message_id, dedupe_hash,
              parse_confidence, symbol_canonical, symbol_raw, side, order_type,
              entry_price, sl_price, tp_prices, has_runner, risk_tag,
              is_scalp, is_swing, is_unofficial, reenter_tag, instructions, meta
            )
            VALUES (
              CAST(:intent_id AS uuid), :provider, :chat_id, CAST(:pk AS uuid), :source_message_id, :dedupe_hash,
              0.950, :symbol, :symbol, 'buy', :order_type,
              :entry_price, 4527, ARRAY[4690,4701]::numeric(18,10)[], false, 'normal',
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
            "order_type": order_type,
            "entry_price": entry_price,
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


def test_limit_legs_store_micro_ladder_requested_entries(db_session):
    source_msg_pk = _seed_intent_plan(
        db_session,
        provider="fredtrading",
        broker="ftmo",
        platform="mt5",
        equity_start="10000",
        symbol="XAUUSD",
        order_type="limit",
        entry_price="4662",
    )

    result = create_trade_family_and_legs(source_msg_pk=source_msg_pk)

    rows = db_session.execute(
        text(
            """
            SELECT leg_index, requested_entry::text, tp_price::text
            FROM trade_legs
            WHERE family_id = CAST(:family_id AS uuid)
            ORDER BY leg_index
            """
        ),
        {"family_id": result.family_id},
    ).mappings().all()

    assert Decimal(rows[0]["requested_entry"]) == Decimal("4662")
    assert Decimal(rows[1]["requested_entry"]) == Decimal("4661")
    assert rows[0]["tp_price"] == "4690.0000000000"
    assert rows[1]["tp_price"] == "4701.0000000000"


def test_market_legs_keep_same_requested_entry_and_sequential_delays(db_session):
    source_msg_pk = _seed_intent_plan(
        db_session,
        provider="fredtrading",
        broker="ftmo",
        platform="mt5",
        equity_start="10000",
        symbol="BTCUSD",
        order_type="market",
        entry_price="91800",
    )

    result = create_trade_family_and_legs(source_msg_pk=source_msg_pk)

    rows = db_session.execute(
        text(
            """
            SELECT leg_index, requested_entry::text, placement_delay_ms
            FROM trade_legs
            WHERE family_id = CAST(:family_id AS uuid)
            ORDER BY leg_index
            """
        ),
        {"family_id": result.family_id},
    ).mappings().all()

    assert Decimal(rows[0]["requested_entry"]) == Decimal("91800")
    assert Decimal(rows[1]["requested_entry"]) == Decimal("91800")
    assert rows[0]["placement_delay_ms"] == 0
    assert rows[1]["placement_delay_ms"] > rows[0]["placement_delay_ms"]
