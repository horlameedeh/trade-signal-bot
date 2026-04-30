import uuid
from decimal import Decimal

import pytest
from sqlalchemy import text

from app.db.session import SessionLocal
from app.services.lifecycle import recompute_family_lifecycle


pytestmark = pytest.mark.integration


@pytest.fixture
def db_session():
    with SessionLocal() as db:
        try:
            yield db
        finally:
            db.rollback()


def _seed_family(db_session, *, side: str = "buy", states: list[str] | None = None) -> str:
    states = states or ["OPEN", "OPEN"]

    account_id = str(uuid.uuid4())
    intent_id = str(uuid.uuid4())
    plan_id = str(uuid.uuid4())
    family_id = str(uuid.uuid4())
    source_msg_pk = str(uuid.uuid4())
    message_id = 940000 + (uuid.uuid4().int % 99999)

    db_session.execute(
        text("INSERT INTO symbols (canonical, asset_class) VALUES ('XAUUSD', 'metal') ON CONFLICT (canonical) DO NOTHING")
    )

    db_session.execute(
        text(
            """
            INSERT INTO broker_accounts (
              account_id, broker, platform, kind, label,
              allowed_providers, equity_start, equity_current, is_active
            )
            VALUES (
              CAST(:account_id AS uuid), 'ftmo', 'mt5', 'personal_live', 'lifecycle-seed',
              ARRAY[]::provider_code[], 10000, 10000, true
            )
            """
        ),
        {"account_id": account_id},
    )

    db_session.execute(
        text(
            """
            INSERT INTO telegram_chats (chat_id, provider_code)
            VALUES (-1001239815745, 'fredtrading')
            ON CONFLICT (chat_id) DO UPDATE SET provider_code='fredtrading'
            """
        )
    )

    db_session.execute(
        text(
            """
            INSERT INTO telegram_messages (msg_pk, chat_id, message_id, text, raw_json)
            VALUES (CAST(:source_msg_pk AS uuid), -1001239815745, :message_id, 'lifecycle seed', '{}'::jsonb)
            ON CONFLICT DO NOTHING
            """
        ),
        {"source_msg_pk": source_msg_pk, "message_id": message_id},
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
              CAST(:intent_id AS uuid), 'fredtrading', -1001239815745, CAST(:source_msg_pk AS uuid),
              :message_id, :dedupe_hash, 0.95, 'XAUUSD', 'XAUUSD', :side, 'market',
              100, 90, ARRAY[110,120]::numeric(18,10)[], false, 'normal',
              false, false, false, false, 'lifecycle seed', '{}'::jsonb
            )
            """
        ),
        {
            "intent_id": intent_id,
            "source_msg_pk": source_msg_pk,
            "message_id": message_id,
            "dedupe_hash": f"lifecycle-{source_msg_pk}",
            "side": side,
        },
    )

    db_session.execute(
        text(
            """
            INSERT INTO trade_plans (plan_id, intent_id, account_id, policy_outcome, requires_approval, policy_reasons)
            VALUES (
              CAST(:plan_id AS uuid),
              CAST(:intent_id AS uuid),
              CAST(:account_id AS uuid),
              'allow',
              false,
              ARRAY['lifecycle-seed']::text[]
            )
            """
        ),
        {"plan_id": plan_id, "intent_id": intent_id, "account_id": account_id},
    )

    db_session.execute(
        text(
            """
            INSERT INTO trade_families (
              family_id, intent_id, plan_id, provider, account_id, chat_id, source_msg_pk,
              symbol_canonical, broker_symbol, side, entry_price, sl_price, tp_count,
              state, is_stub, management_rules, meta
            )
            VALUES (
              CAST(:family_id AS uuid), CAST(:intent_id AS uuid), CAST(:plan_id AS uuid),
              'fredtrading', CAST(:account_id AS uuid), -1001239815745, CAST(:source_msg_pk AS uuid),
              'XAUUSD', 'XAUUSD', :side, 100, 90, :tp_count,
              'OPEN', false, '{}'::jsonb, '{}'::jsonb
            )
            """
        ),
        {
            "family_id": family_id,
            "intent_id": intent_id,
            "plan_id": plan_id,
            "account_id": account_id,
            "source_msg_pk": source_msg_pk,
            "side": side,
            "tp_count": len(states),
        },
    )

    for idx, state in enumerate(states, start=1):
        tp = 100 + (idx * 10)
        db_session.execute(
            text(
                """
                INSERT INTO trade_legs (
                  leg_id, family_id, plan_id, idx, leg_index, entry_price,
                  requested_entry, sl_price, tp_price, lots, state, placement_delay_ms
                )
                VALUES (
                  gen_random_uuid(), CAST(:family_id AS uuid), CAST(:plan_id AS uuid),
                  :idx, :idx, 100, 100, 90, :tp, 1.00, :state, 0
                )
                """
            ),
            {"family_id": family_id, "plan_id": plan_id, "idx": idx, "tp": tp, "state": state},
        )

    db_session.commit()
    return family_id


def test_lifecycle_open_family_computes_exposure_and_floating_pnl(db_session):
    family_id = _seed_family(db_session, states=["OPEN", "OPEN"])

    result = recompute_family_lifecycle(family_id=family_id, mark_price="105")

    assert result.family_state == "OPEN"
    assert result.legs_open == 2
    assert Decimal(result.floating_pnl) == Decimal("10.00")
    assert Decimal(result.exposure_at_sl) == Decimal("20.00")


def test_lifecycle_partially_closed_family_realizes_tp_hit(db_session):
    family_id = _seed_family(db_session, states=["TP_HIT", "OPEN"])

    result = recompute_family_lifecycle(family_id=family_id, mark_price="105")

    assert result.family_state == "PARTIALLY_CLOSED"
    assert result.legs_closed == 1
    assert result.legs_open == 1
    assert Decimal(result.realized_pnl) == Decimal("10.00")


def test_lifecycle_closed_family_realizes_tp_and_sl(db_session):
    family_id = _seed_family(db_session, states=["TP_HIT", "SL_HIT"])

    result = recompute_family_lifecycle(family_id=family_id)

    assert result.family_state == "CLOSED"
    assert result.legs_closed == 2
    assert Decimal(result.realized_pnl) == Decimal("0.00")


def test_lifecycle_sell_side_pnl(db_session):
    family_id = _seed_family(db_session, side="sell", states=["OPEN"])

    result = recompute_family_lifecycle(family_id=family_id, mark_price="95")

    assert result.family_state == "OPEN"
    assert Decimal(result.floating_pnl) == Decimal("5.00")


def test_lifecycle_persists_meta(db_session):
    family_id = _seed_family(db_session, states=["OPEN", "OPEN"])

    recompute_family_lifecycle(family_id=family_id, mark_price="105")

    row = db_session.execute(
        text(
            """
            SELECT state, meta->'lifecycle' AS lifecycle
            FROM trade_families
            WHERE family_id = CAST(:family_id AS uuid)
            """
        ),
        {"family_id": family_id},
    ).mappings().first()

    assert row["state"] == "OPEN"
    assert row["lifecycle"]["legs_total"] == 2
    assert row["lifecycle"]["legs_open"] == 2
