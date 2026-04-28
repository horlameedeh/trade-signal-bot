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


def _seed_account(db_session, *, broker: str, equity_start: str) -> str:
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
            "label": f"seed-{broker}-{equity_start}",
            "equity_start": equity_start,
        },
    )
    return account_id


def _seed_intent_plan(db_session, *, provider: str, broker: str, equity_start: str, tp_prices_sql: str, risk_tag: str = "normal", is_swing: bool = False, instructions: str = "seed") -> str:
    chat_id = -1001239815745
    source_msg_pk = str(uuid.uuid4())
    source_message_id = 900000 + (uuid.UUID(source_msg_pk).int % 99999)
    intent_id = str(uuid.uuid4())
    account_id = _seed_account(db_session, broker=broker, equity_start=equity_start)

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
            VALUES (CAST(:pk AS uuid), :chat_id, :source_message_id, :txt, '{}'::jsonb)
            ON CONFLICT (chat_id, message_id) DO NOTHING
            """
        ),
        {
            "pk": source_msg_pk,
            "chat_id": chat_id,
            "source_message_id": source_message_id,
            "txt": instructions,
        },
    )

    db_session.execute(
        text(
            f"""
            INSERT INTO trade_intents (
              intent_id,
              provider,
              chat_id,
              source_msg_pk,
              source_message_id,
              dedupe_hash,
              parse_confidence,
              symbol_canonical,
              symbol_raw,
              side,
              order_type,
              entry_price,
              sl_price,
              tp_prices,
              has_runner,
              risk_tag,
              is_scalp,
              is_swing,
              is_unofficial,
              reenter_tag,
              instructions,
              meta
            )
            VALUES (
                            CAST(:intent_id AS uuid),
              :provider,
              :chat_id,
                            CAST(:pk AS uuid),
                              :source_message_id,
              :dedupe_hash,
              0.950,
              'XAUUSD',
              'XAUUSD',
              'buy',
              'market',
              2025,
              2010,
              {tp_prices_sql},
              false,
              :risk_tag,
              false,
              :is_swing,
              false,
              false,
              :instructions,
              '{{}}'::jsonb
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
            "risk_tag": risk_tag,
            "is_swing": is_swing,
            "instructions": instructions,
        },
    )

    db_session.execute(
        text(
            """
            INSERT INTO trade_plans (
              intent_id,
              account_id,
              policy_outcome,
              requires_approval,
              policy_reasons
            )
            VALUES (
                            CAST(:intent_id AS uuid),
                            CAST(:account_id AS uuid),
              'allow'::policy_outcome,
              false,
              ARRAY['seed']::text[]
            )
            """
        ),
        {"intent_id": intent_id, "account_id": account_id},
    )

    db_session.commit()
    return source_msg_pk


def test_trade_writer_uses_fred_10k_ftmo_policy(db_session):
    source_msg_pk = _seed_intent_plan(
        db_session,
        provider="fredtrading",
        broker="ftmo",
        equity_start="10000",
        tp_prices_sql="ARRAY[2030,2040,2050,2060]::numeric(18,10)[]",
    )

    result = create_trade_family_and_legs(source_msg_pk=source_msg_pk)

    assert result.total_lots == "0.20"
    assert result.lot_per_leg == "0.05"

    rows = db_session.execute(
        text(
            """
            SELECT lots
            FROM trade_legs
            WHERE family_id = CAST(:family_id AS uuid)
            ORDER BY leg_index
            """
        ),
        {"family_id": result.family_id},
    ).scalars().all()

    assert rows == [Decimal("0.05"), Decimal("0.05"), Decimal("0.05"), Decimal("0.05")]


def test_trade_writer_applies_half_risk_scaling(db_session):
    source_msg_pk = _seed_intent_plan(
        db_session,
        provider="fredtrading",
        broker="ftmo",
        equity_start="20000",
        tp_prices_sql="ARRAY[2030,2040,2050,2060]::numeric(18,10)[]",
        risk_tag="half",
    )

    result = create_trade_family_and_legs(source_msg_pk=source_msg_pk)

    assert result.total_lots == "0.20"
    assert result.lot_per_leg == "0.05"


def test_trade_writer_applies_swing_policy(db_session):
    source_msg_pk = _seed_intent_plan(
        db_session,
        provider="fredtrading",
        broker="ftmo",
        equity_start="100000",
        tp_prices_sql="ARRAY[2030,2040,2050,2060]::numeric(18,10)[]",
        is_swing=True,
    )

    result = create_trade_family_and_legs(source_msg_pk=source_msg_pk)

    assert result.total_lots == "0.16"
    assert result.lot_per_leg == "0.04"


def test_trade_writer_applies_special_trying_something_out_policy(db_session):
    source_msg_pk = _seed_intent_plan(
        db_session,
        provider="fredtrading",
        broker="ftmo",
        equity_start="100000",
        tp_prices_sql="ARRAY[4690,4701]::numeric(18,10)[]",
        instructions="I’m trying something out on a 5K side account I setup to have some fun on…",
    )

    result = create_trade_family_and_legs(source_msg_pk=source_msg_pk)

    assert result.total_lots == "0.80"
    assert result.lot_per_leg == "0.40"


def test_billio_uses_same_permanent_table(db_session):
    source_msg_pk = _seed_intent_plan(
        db_session,
        provider="billionaire_club",
        broker="traderscale",
        equity_start="20000",
        tp_prices_sql="ARRAY[2030,2040,2050,2060]::numeric(18,10)[]",
    )

    result = create_trade_family_and_legs(source_msg_pk=source_msg_pk)

    assert result.total_lots == "0.40"
    assert result.lot_per_leg == "0.10"
