import uuid
from decimal import Decimal

import pytest
from sqlalchemy import text

from app.db.session import SessionLocal
from app.services.trade_writer import create_trade_family_and_legs
from app.services.management import apply_be_at_tp1


pytestmark = pytest.mark.integration


@pytest.fixture
def db_session():
    with SessionLocal() as db:
        try:
            yield db
        finally:
            db.rollback()


def _seed_family(db_session, *, source_msg_pk: str):
    chat_id = -1001239815745
    source_message_id = 900000 + (uuid.UUID(source_msg_pk).int % 99999)

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
            VALUES (CAST(:pk AS uuid), :chat_id, :source_message_id, 'seed', '{}'::jsonb)
            ON CONFLICT (chat_id, message_id) DO NOTHING
            """
        ),
        {"pk": source_msg_pk, "chat_id": chat_id, "source_message_id": source_message_id},
    )

    intent_id = str(uuid.uuid4())

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
                            :source_message_id,
              :dedupe_hash,
              0.950,
              'XAUUSD',
              'XAUUSD',
              'buy',
              'market',
              2025,
              2010,
              ARRAY[2030,2040,2050]::numeric(18,10)[],
              false,
              'normal',
              false,
              false,
              false,
              false,
              'seed',
              '{}'::jsonb
            )
            """
        ),
        {
            "intent_id": intent_id,
            "chat_id": chat_id,
            "pk": source_msg_pk,
            "source_message_id": source_message_id,
            "dedupe_hash": f"seed-{source_msg_pk}",
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
            """
        ),
        {"pk": source_msg_pk},
    )

    db_session.commit()

    return create_trade_family_and_legs(
        source_msg_pk=source_msg_pk,
        total_lot="0.30",
    ).family_id


def test_tp1_close_moves_sl_to_entry_on_remaining_legs(db_session):
    family_id = _seed_family(db_session, source_msg_pk=str(uuid.uuid4()))

    # Close TP1 leg
    db_session.execute(
        text(
            """
            UPDATE trade_legs
            SET state = 'CLOSED'
            WHERE family_id = CAST(:fid AS uuid)
              AND leg_index = 1
            """
        ),
        {"fid": family_id},
    )
    db_session.commit()

    result = apply_be_at_tp1(family_id=family_id)
    assert result.reason == "be_at_tp1_applied"
    assert result.legs_updated == 2

    rows = db_session.execute(
        text(
            """
            SELECT leg_index, sl_price
            FROM trade_legs
            WHERE family_id = CAST(:fid AS uuid)
              AND leg_index IN (2,3)
            ORDER BY leg_index
            """
        ),
        {"fid": family_id},
    ).mappings().all()

    assert rows[0]["sl_price"] == Decimal("2025")
    assert rows[1]["sl_price"] == Decimal("2025")


def test_no_action_if_tp1_not_closed(db_session):
    family_id = _seed_family(db_session, source_msg_pk=str(uuid.uuid4()))

    result = apply_be_at_tp1(family_id=family_id)
    assert result.reason == "tp1_not_closed"
    assert result.legs_updated == 0
