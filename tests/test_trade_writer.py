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


def _seed_intent_and_plan(
    db_session,
    *,
    source_msg_pk: str,
    tp_prices: list[Decimal],
    sl_price: Decimal | None = Decimal("2010"),
):
    chat_id = -1001239815745
    message_id = 980000 + (uuid.UUID(source_msg_pk).int % 100000)

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
            VALUES (CAST(:pk AS uuid), :chat_id, :message_id, 'seed', '{}'::jsonb)
            ON CONFLICT (chat_id, message_id) DO NOTHING
            """
        ),
        {"pk": source_msg_pk, "chat_id": chat_id, "message_id": message_id},
    )

    db_session.execute(
        text(
            """
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
              'fredtrading',
              :chat_id,
              CAST(:pk AS uuid),
              :message_id,
              :dedupe_hash,
              0.950,
              'XAUUSD',
              'XAUUSD',
              'buy',
              'market',
              2025,
              :sl_price,
              :tp_prices,
              false,
              'normal',
              false,
              false,
              false,
              false,
              'seed',
              '{}'::jsonb
            )
            ON CONFLICT (source_msg_pk) DO NOTHING
            """
        ),
        {
            "intent_id": str(uuid.uuid4()),
            "chat_id": chat_id,
            "pk": source_msg_pk,
            "message_id": message_id,
            "dedupe_hash": f"seed-{source_msg_pk}",
            "sl_price": sl_price,
            "tp_prices": tp_prices,
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
            SELECT
              ti.intent_id,
              (
                SELECT ba.account_id
                FROM broker_accounts ba
                WHERE ba.is_active = true
                LIMIT 1
              ),
              'allow'::policy_outcome,
              false,
              ARRAY['seed']::text[]
            FROM trade_intents ti
            WHERE ti.source_msg_pk = CAST(:pk AS uuid)
              AND NOT EXISTS (
                SELECT 1 FROM trade_plans tp WHERE tp.intent_id = ti.intent_id
              )
            """
        ),
        {"pk": source_msg_pk},
    )

    db_session.commit()


def test_3_tp_trade_creates_3_legs(db_session):
    source_msg_pk = str(uuid.uuid4())
    _seed_intent_and_plan(
        db_session,
        source_msg_pk=source_msg_pk,
        tp_prices=[Decimal("2030"), Decimal("2040"), Decimal("2050")],
    )

    result = create_trade_family_and_legs(
        source_msg_pk=source_msg_pk,
        total_lot="0.30",
    )

    assert result.legs_created == 3
    assert result.is_stub is False

    row = db_session.execute(
        text("SELECT COUNT(*) FROM trade_legs WHERE family_id = CAST(:family_id AS uuid)"),
        {"family_id": result.family_id},
    ).scalar()
    assert row == 3


def test_even_split_across_legs(db_session):
    source_msg_pk = str(uuid.uuid4())
    _seed_intent_and_plan(
        db_session,
        source_msg_pk=source_msg_pk,
        tp_prices=[Decimal("2030"), Decimal("2040"), Decimal("2050")],
    )

    result = create_trade_family_and_legs(
        source_msg_pk=source_msg_pk,
        total_lot="0.30",
    )

    assert result.lot_per_leg == "0.10"

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

    assert [Decimal(str(v)) for v in rows] == [Decimal("0.10"), Decimal("0.10"), Decimal("0.10")]


def test_stub_trade_creates_one_pending_update_family(db_session):
    source_msg_pk = str(uuid.uuid4())
    _seed_intent_and_plan(
        db_session,
        source_msg_pk=source_msg_pk,
        tp_prices=[],
        sl_price=None,
    )

    result = create_trade_family_and_legs(
        source_msg_pk=source_msg_pk,
        total_lot="0.10",
    )

    assert result.legs_created == 1
    assert result.is_stub is True

    family = db_session.execute(
        text(
            """
            SELECT state, is_stub, tp_count
            FROM trade_families
            WHERE family_id = CAST(:family_id AS uuid)
            """
        ),
        {"family_id": result.family_id},
    ).mappings().first()

    assert family["state"] == "PENDING_UPDATE"
    assert family["is_stub"] is True
