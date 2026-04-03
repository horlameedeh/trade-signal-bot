import uuid
from decimal import Decimal

import pytest
from sqlalchemy import text

from app.db.session import SessionLocal
from app.parsing.parser import parse_message
from app.services.trade_writer import create_trade_family_and_legs
from app.services.update_applier import apply_update_to_family


pytestmark = pytest.mark.integration


@pytest.fixture
def db_session():
    with SessionLocal() as db:
        try:
            yield db
        finally:
            db.rollback()


def _seed_intent_plan_and_family(db_session, *, source_msg_pk: str):
    chat_id = -1003254187278
    message_id = 970000 + (uuid.UUID(source_msg_pk).int % 100000)

    db_session.execute(
        text(
            """
            INSERT INTO telegram_chats (chat_id, provider_code)
            VALUES (:chat_id, 'billionaire_club')
            ON CONFLICT (chat_id) DO UPDATE SET provider_code='billionaire_club'
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
              'billionaire_club',
              :chat_id,
                            CAST(:pk AS uuid),
                            :message_id,
              :dedupe_hash,
              0.950,
              'XAUUSD',
              'XAUUSD',
              'buy',
              'market',
              4922,
              4916,
              ARRAY[4925,4928,4934]::numeric(18,10)[],
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
            "message_id": message_id,
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

    family = create_trade_family_and_legs(
        source_msg_pk=source_msg_pk,
        total_lot="0.30",
    )
    return family.family_id


def test_move_sl_to_be_sets_sl_to_entry_on_open_legs(db_session):
    family_id = _seed_intent_plan_and_family(db_session, source_msg_pk=str(uuid.uuid4()))

    parsed = parse_message("billionaire_club", "Position is running nicely! I will Move stop loss to break even!")
    result = apply_update_to_family(family_id=family_id, parsed=parsed)

    assert result.family_updated is True
    assert result.legs_updated >= 1

    fam = db_session.execute(
        text("SELECT entry_price::text, sl_price::text FROM trade_families WHERE family_id = CAST(:fid AS uuid)"),
        {"fid": family_id},
    ).mappings().first()

    assert fam["entry_price"] == fam["sl_price"]


def test_move_tp4s_to_price_updates_target_leg(db_session):
    family_id = _seed_intent_plan_and_family(db_session, source_msg_pk=str(uuid.uuid4()))

    # add a 4th leg so TP4 exists
    plan_id = db_session.execute(
        text("SELECT plan_id::text FROM trade_families WHERE family_id = CAST(:fid AS uuid)"),
        {"fid": family_id},
    ).scalar()

    db_session.execute(
        text(
            """
            INSERT INTO trade_legs (family_id, plan_id, idx, leg_index, entry_price, sl_price, tp_price, state, lots)
            VALUES (CAST(:fid AS uuid), CAST(:plan_id AS uuid), 4, 4, 4922, 4916, 4940, 'OPEN', 0.10)
            """
        ),
        {"fid": family_id, "plan_id": plan_id},
    )
    db_session.commit()

    parsed = parse_message("fredtrading", "Move TP4s to 4527")
    result = apply_update_to_family(family_id=family_id, parsed=parsed)

    assert result.legs_updated >= 1

    tp4 = db_session.execute(
        text(
            """
            SELECT tp_price::text
            FROM trade_legs
                        WHERE family_id = CAST(:fid AS uuid)
              AND leg_index = 4
            """
        ),
        {"fid": family_id},
    ).scalar()

    assert Decimal(tp4) == Decimal("4527")


def test_stub_completion_replaces_leg_targets(db_session):
    source_msg_pk = str(uuid.uuid4())
    family_id = _seed_intent_plan_and_family(db_session, source_msg_pk=source_msg_pk)

    parsed = parse_message(
        "mubeen",
        "XAUUSD BUY LIMIT\nEnter 4946\nSL 4938\nTP1 4950\nTP2 4953\nTP3 4956\nTP4 4970 4985",
    )
    # Reuse add_tps behavior by applying parsed update-style payload manually:
    # easiest path: create an UPDATE-like parsed object from parser output isn't necessary here,
    # so we use parsed tps as update add_tps through a shallow override.
    upd = parsed.update if parsed.update else None
    if upd is None:
        from app.parsing.models import UpdateIntent
        parsed = parsed.__class__(**{
            **parsed.__dict__,
            "message_type": __import__("app.parsing.models", fromlist=["MessageType"]).MessageType.UPDATE,
            "update": UpdateIntent(symbol=parsed.symbol, raw_symbol=parsed.raw_symbol, add_tps=parsed.tps),
        })

    result = apply_update_to_family(family_id=family_id, parsed=parsed)
    assert result.legs_updated >= 3

    rows = db_session.execute(
        text(
            """
            SELECT leg_index, tp_price::text
            FROM trade_legs
            WHERE family_id = CAST(:fid AS uuid)
            ORDER BY leg_index
            """
        ),
        {"fid": family_id},
    ).mappings().all()

    assert Decimal(rows[0]["tp_price"]) == Decimal("4950")
