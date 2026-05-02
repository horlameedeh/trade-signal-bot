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


def test_trade_writer_uses_small_account_currency_size(db_session):
    account_id = str(uuid.uuid4())
    intent_id = str(uuid.uuid4())
    source_msg_pk = str(uuid.uuid4())
    message_id = 1500000 + (uuid.uuid4().int % 99999)

    db_session.execute(text("""
        INSERT INTO symbols (canonical, asset_class)
        VALUES ('XAUUSD', 'metal')
        ON CONFLICT (canonical) DO NOTHING
    """))

    db_session.execute(
        text("""
            INSERT INTO broker_accounts (
              account_id, broker, platform, kind, label,
              allowed_providers, equity_start, equity_current,
              account_size, account_currency, is_active
            )
            VALUES (
                            CAST(:account_id AS uuid), 'vantage', 'mt5', 'personal_live', 'small-vantage-test',
              ARRAY[]::provider_code[], 500, 500,
              500, 'GBP', true
            )
        """),
        {"account_id": account_id},
    )

    db_session.execute(text("""
        INSERT INTO telegram_chats (chat_id, provider_code)
        VALUES (-1001239815745, 'fredtrading')
        ON CONFLICT (chat_id) DO UPDATE SET provider_code='fredtrading'
    """))

    db_session.execute(
        text("""
            INSERT INTO telegram_messages (msg_pk, chat_id, message_id, text, raw_json)
            VALUES (
              CAST(:source_msg_pk AS uuid), -1001239815745, :message_id,
              'BUY XAUUSD\nENTRY 4639\nSL 4633\nTP1 4645\nTP2 4655\nTP3 4665\nTP4 4675',
              '{}'::jsonb
            )
        """),
        {"source_msg_pk": source_msg_pk, "message_id": message_id},
    )

    db_session.execute(
        text("""
            INSERT INTO trade_intents (
              intent_id, provider, chat_id, source_msg_pk, source_message_id, dedupe_hash,
              parse_confidence, symbol_canonical, symbol_raw, side, order_type,
              entry_price, sl_price, tp_prices, has_runner, risk_tag,
              is_scalp, is_swing, is_unofficial, reenter_tag, instructions, meta
            )
            VALUES (
              CAST(:intent_id AS uuid), 'fredtrading', -1001239815745, CAST(:source_msg_pk AS uuid),
              :message_id, :dedupe_hash, 0.95, 'XAUUSD', 'XAUUSD', 'buy', 'market',
              4639, 4633, ARRAY[4645,4655,4665,4675]::numeric(18,10)[], false, 'normal',
              false, false, false, false, 'small account test', '{}'::jsonb
            )
        """),
        {
            "intent_id": intent_id,
            "source_msg_pk": source_msg_pk,
            "message_id": message_id,
            "dedupe_hash": f"small-account-{source_msg_pk}",
        },
    )

    db_session.execute(
        text("""
            INSERT INTO trade_plans (
              plan_id, intent_id, account_id, policy_outcome, requires_approval, policy_reasons
            )
            VALUES (
              gen_random_uuid(), CAST(:intent_id AS uuid), CAST(:account_id AS uuid),
              'allow', false, ARRAY['small-account-test']::text[]
            )
        """),
        {"intent_id": intent_id, "account_id": account_id},
    )

    db_session.commit()

    result = create_trade_family_and_legs(source_msg_pk=source_msg_pk)

    assert result.legs_created == 4
    assert result.total_lots == "0.04"
    assert result.lot_per_leg == "0.01"

    with SessionLocal() as check_db:
        lots = check_db.execute(
            text("""
                SELECT lots::text
                FROM trade_legs tl
                JOIN trade_families tf ON tf.family_id = tl.family_id
                WHERE tf.source_msg_pk = CAST(:source_msg_pk AS uuid)
                ORDER BY tl.idx
            """),
            {"source_msg_pk": source_msg_pk},
        ).scalars().all()

    assert [Decimal(v) for v in lots] == [
        Decimal("0.01"),
        Decimal("0.01"),
        Decimal("0.01"),
        Decimal("0.01"),
    ]
