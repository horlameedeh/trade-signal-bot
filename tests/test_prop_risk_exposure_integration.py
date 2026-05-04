import uuid
from decimal import Decimal

import pytest
from sqlalchemy import text

from app.db.session import SessionLocal
from app.risk.exposure import (
    build_exposure_snapshot,
    compute_current_open_risk_for_account,
    compute_family_risk_at_sl,
    evaluate_family_prop_risk,
)


pytestmark = pytest.mark.integration


def _cleanup_risk_test_data(db) -> None:
    db.execute(
        text(
            """
            DELETE FROM trade_legs tl
            USING trade_families tf, broker_accounts ba
            WHERE tl.family_id = tf.family_id
              AND tf.account_id = ba.account_id
              AND ba.label = 'risk-seed'
            """
        )
    )
    db.execute(
        text(
            """
            DELETE FROM trade_families tf
            USING broker_accounts ba
            WHERE tf.account_id = ba.account_id
              AND ba.label = 'risk-seed'
            """
        )
    )
    db.execute(
        text(
            """
            DELETE FROM trade_plans tp
            USING broker_accounts ba
            WHERE tp.account_id = ba.account_id
              AND ba.label = 'risk-seed'
            """
        )
    )
    db.execute(text("DELETE FROM trade_intents WHERE dedupe_hash LIKE 'risk-%'"))
    db.execute(text("DELETE FROM telegram_messages WHERE text LIKE 'risk seed%'"))
    db.execute(text("DELETE FROM broker_accounts WHERE label = 'risk-seed'"))
    db.commit()


@pytest.fixture
def db_session():
    with SessionLocal() as db:
        _cleanup_risk_test_data(db)
    with SessionLocal() as db:
        try:
            yield db
        finally:
            db.rollback()
    with SessionLocal() as db:
        _cleanup_risk_test_data(db)


def _seed_family(
    db_session,
    *,
    broker: str = "ftmo",
    equity_start: str = "10000",
    entry: str = "100",
    sl: str = "90",
    lots: str = "1.00",
    legs: int = 1,
) -> tuple[str, str]:
    account_id = str(uuid.uuid4())
    intent_id = str(uuid.uuid4())
    plan_id = str(uuid.uuid4())
    family_id = str(uuid.uuid4())
    source_msg_pk = str(uuid.uuid4())
    message_id = 870000 + (uuid.uuid4().int % 99999)

    db_session.execute(
        text("INSERT INTO symbols (canonical, asset_class) VALUES ('XAUUSD', 'metal') ON CONFLICT (canonical) DO NOTHING")
    )

    db_session.execute(
        text(
            """
            UPDATE broker_accounts
            SET is_active = false
            WHERE broker = :broker
              AND platform = 'mt5'
              AND is_active = true
            """
        ),
        {"broker": broker},
    )

    db_session.execute(
        text(
            """
            INSERT INTO broker_accounts (
              account_id, broker, platform, kind, label,
              allowed_providers, equity_start, equity_current, is_active
            )
            VALUES (
              CAST(:account_id AS uuid), :broker, 'mt5', 'personal_live', 'risk-seed',
              ARRAY[]::provider_code[], :equity_start, :equity_start, true
            )
            """
        ),
        {"account_id": account_id, "broker": broker, "equity_start": equity_start},
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
            VALUES (CAST(:source_msg_pk AS uuid), -1001239815745, :message_id, 'risk seed', '{}'::jsonb)
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
              :message_id, :dedupe_hash, 0.95, 'XAUUSD', 'XAUUSD', 'buy', 'market',
              :entry, :sl, ARRAY[110]::numeric(18,10)[], false, 'normal',
              false, false, false, false, 'risk seed', '{}'::jsonb
            )
            """
        ),
        {
            "intent_id": intent_id,
            "source_msg_pk": source_msg_pk,
            "message_id": message_id,
            "dedupe_hash": f"risk-{source_msg_pk}",
            "entry": entry,
            "sl": sl,
        },
    )

    db_session.execute(
        text(
            """
            INSERT INTO trade_plans (plan_id, intent_id, account_id, policy_outcome, requires_approval, policy_reasons)
            VALUES (
              CAST(:plan_id AS uuid), CAST(:intent_id AS uuid), CAST(:account_id AS uuid),
              'allow', false, ARRAY['risk-seed']::text[]
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
              'XAUUSD', 'XAUUSD', 'buy', :entry, :sl, :legs, 'OPEN', false, '{}'::jsonb, '{}'::jsonb
            )
            """
        ),
        {
            "family_id": family_id,
            "intent_id": intent_id,
            "plan_id": plan_id,
            "account_id": account_id,
            "source_msg_pk": source_msg_pk,
            "entry": entry,
            "sl": sl,
            "legs": legs,
        },
    )

    for idx in range(1, legs + 1):
        db_session.execute(
            text(
                """
                INSERT INTO trade_legs (
                  leg_id, family_id, plan_id, idx, leg_index, entry_price,
                  requested_entry, sl_price, tp_price, lots, state, placement_delay_ms
                )
                VALUES (
                  gen_random_uuid(), CAST(:family_id AS uuid), CAST(:plan_id AS uuid),
                  :idx, :idx, :entry, :entry, :sl, 110, :lots, 'OPEN', 0
                )
                """
            ),
            {"family_id": family_id, "plan_id": plan_id, "idx": idx, "entry": entry, "sl": sl, "lots": lots},
        )

    db_session.commit()
    return family_id, account_id


def test_compute_family_risk_at_sl(db_session):
    family_id, _ = _seed_family(db_session, entry="100", sl="90", lots="1.00", legs=2)

    risk = compute_family_risk_at_sl(family_id=family_id)

    assert risk == Decimal("20.00")


def test_current_open_risk_excludes_target_family(db_session):
    family_one, account_id = _seed_family(db_session, entry="100", sl="90", lots="1.00", legs=1)

    # second family on same account
    family_two = str(uuid.uuid4())
    plan_id = db_session.execute(
        text("SELECT plan_id::text FROM trade_families WHERE family_id = CAST(:family_id AS uuid)"),
        {"family_id": family_one},
    ).scalar()
    intent_id = db_session.execute(
        text("SELECT intent_id::text FROM trade_families WHERE family_id = CAST(:family_id AS uuid)"),
        {"family_id": family_one},
    ).scalar()
    source_msg_pk = str(uuid.uuid4())

    db_session.execute(
        text(
            """
            INSERT INTO telegram_messages (msg_pk, chat_id, message_id, text, raw_json)
            VALUES (CAST(:source_msg_pk AS uuid), -1001239815745, :message_id, 'risk seed 2', '{}'::jsonb)
            ON CONFLICT DO NOTHING
            """
        ),
        {"source_msg_pk": source_msg_pk, "message_id": 880000 + (uuid.uuid4().int % 99999)},
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
              'XAUUSD', 'XAUUSD', 'buy', 200, 190, 1, 'OPEN', false, '{}'::jsonb, '{}'::jsonb
            )
            """
        ),
        {
            "family_id": family_two,
            "intent_id": intent_id,
            "plan_id": plan_id,
            "account_id": account_id,
            "source_msg_pk": source_msg_pk,
        },
    )

    db_session.execute(
        text(
            """
            INSERT INTO trade_legs (
              leg_id, family_id, plan_id, idx, leg_index, entry_price,
              requested_entry, sl_price, tp_price, lots, state, placement_delay_ms
            )
            VALUES (
              gen_random_uuid(), CAST(:family_id AS uuid), CAST(:plan_id AS uuid),
              99, 1, 200, 200, 190, 210, 2.00, 'OPEN', 0
            )
            """
        ),
        {"family_id": family_two, "plan_id": plan_id},
    )
    db_session.commit()

    current = compute_current_open_risk_for_account(
        account_id=account_id,
        exclude_family_id=family_one,
    )

    assert current == Decimal("20.00")


def test_build_exposure_snapshot(db_session):
    family_id, _ = _seed_family(db_session, broker="ftmo", equity_start="10000", entry="100", sl="90", lots="1.00", legs=1)

    snap = build_exposure_snapshot(family_id=family_id)

    assert snap.broker == "ftmo"
    assert snap.starting_balance in ("10000.0000000000", "10000", "10000.00")
    from decimal import Decimal
    assert Decimal(snap.new_trade_risk_at_sl) == Decimal("10.00")


def test_evaluate_family_prop_risk_allows_safe_trade(db_session):
    family_id, _ = _seed_family(db_session, broker="ftmo", equity_start="10000", entry="100", sl="90", lots="1.00", legs=1)

    result = evaluate_family_prop_risk(family_id=family_id)

    assert result.decision == "allow"


def test_evaluate_family_prop_risk_blocks_breach(db_session):
    # equity_start=100, daily_limit=5 (5%), risk=(100-90)*1.0=10 >= 5 => block
    family_id, _ = _seed_family(db_session, broker="ftmo", equity_start="100", entry="100", sl="90", lots="1.00", legs=1)

    result = evaluate_family_prop_risk(family_id=family_id)

    assert result.decision == "block"
    assert "daily_loss_limit_breached" in result.reasons or "total_loss_limit_breached" in result.reasons
