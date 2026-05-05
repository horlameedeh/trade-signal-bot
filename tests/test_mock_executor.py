import uuid

import pytest
from sqlalchemy import text

from app.db.session import SessionLocal
from app.execution.mock_executor import plan_family_execution


pytestmark = pytest.mark.integration


def _cleanup_mock_executor_data(db) -> None:
    db.execute(text("DELETE FROM mock_executions WHERE family_id IN (SELECT family_id FROM trade_families WHERE account_id IN (SELECT account_id FROM broker_accounts WHERE label = 'mock-executor-seed'))"))
    db.execute(text("DELETE FROM trade_legs WHERE family_id IN (SELECT family_id FROM trade_families WHERE account_id IN (SELECT account_id FROM broker_accounts WHERE label = 'mock-executor-seed'))"))
    db.execute(text("DELETE FROM trade_families WHERE account_id IN (SELECT account_id FROM broker_accounts WHERE label = 'mock-executor-seed')"))
    db.execute(text("DELETE FROM trade_plans WHERE account_id IN (SELECT account_id FROM broker_accounts WHERE label = 'mock-executor-seed')"))
    db.execute(text("DELETE FROM trade_intents WHERE dedupe_hash LIKE 'mock-executor-%'"))
    db.execute(text("DELETE FROM broker_accounts WHERE label = 'mock-executor-seed'"))
    db.commit()


@pytest.fixture
def db_session():
    with SessionLocal() as db:
        _cleanup_mock_executor_data(db)
        try:
            yield db
        finally:
            db.rollback()
    with SessionLocal() as db:
        _cleanup_mock_executor_data(db)


def _seed_family_and_legs(db_session):
    account_id = str(uuid.uuid4())
    family_id = str(uuid.uuid4())
    plan_id = str(uuid.uuid4())
    source_msg_pk = str(uuid.uuid4())
    intent_id = str(uuid.uuid4())
    message_id = 1_700_000_000 + (uuid.UUID(source_msg_pk).int % 100_000_000)

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
              CAST(:account_id AS uuid), 'ftmo', 'mt5', 'personal_live', 'mock-executor-seed',
              ARRAY[]::provider_code[], 10000, 10000, false
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
            VALUES (CAST(:source_msg_pk AS uuid), -1001239815745, :message_id, 'mock executor seed', '{}'::jsonb)
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
              4662, 4527, ARRAY[4690,4701]::numeric(18,10)[], false, 'normal',
              false, false, false, false, 'mock executor seed', '{}'::jsonb
            )
            """
        ),
        {
            "intent_id": intent_id,
            "source_msg_pk": source_msg_pk,
            "message_id": message_id,
            "dedupe_hash": f"mock-executor-{source_msg_pk}",
        },
    )

    db_session.execute(
        text(
            """
            INSERT INTO trade_plans (
              plan_id, intent_id, account_id, policy_outcome, requires_approval, policy_reasons
            )
            VALUES (
              CAST(:plan_id AS uuid),
              CAST(:intent_id AS uuid),
              CAST(:account_id AS uuid),
              'allow'::policy_outcome,
              false,
              ARRAY['seed']::text[]
            )
            """
        ),
                {"plan_id": plan_id, "intent_id": intent_id, "account_id": account_id},
    )

    db_session.execute(
        text(
            """
            INSERT INTO trade_families (
                            family_id, intent_id, provider, account_id, chat_id, source_msg_pk,
              symbol_canonical, broker_symbol, side, entry_price, sl_price,
              tp_count, state, is_stub, management_rules, meta
            )
            VALUES (
              CAST(:family_id AS uuid),
                            CAST(:intent_id AS uuid),
              'fredtrading',
                            CAST(:account_id AS uuid),
              -1001239815745,
              CAST(:source_msg_pk AS uuid),
              'XAUUSD',
              'XAUUSD',
              'buy',
              4662,
              4527,
              2,
              'OPEN',
              false,
              '{}'::jsonb,
              '{}'::jsonb
            )
            """
        ),
        {
            "family_id": family_id,
            "source_msg_pk": source_msg_pk,
            "intent_id": intent_id,
            "account_id": account_id,
        },
    )

    for idx, tp in enumerate([4690, 4701], start=1):
        db_session.execute(
            text(
                """
                INSERT INTO trade_legs (
                  leg_id, family_id, plan_id, idx, leg_index, entry_price,
                  requested_entry, sl_price, tp_price, lots, state, placement_delay_ms
                )
                VALUES (
                  gen_random_uuid(),
                  CAST(:family_id AS uuid),
                  CAST(:plan_id AS uuid),
                  :idx,
                  :idx,
                  4662,
                  :requested_entry,
                  4527,
                  :tp,
                  0.04,
                  'OPEN',
                  :delay
                )
                """
            ),
            {
                "family_id": family_id,
                "plan_id": plan_id,
                "idx": idx,
                "requested_entry": 4662 - (idx - 1),
                "tp": tp,
                "delay": (idx - 1) * 100,
            },
        )

    db_session.commit()
    return family_id


def test_mock_executor_creates_one_execution_per_leg(db_session):
    family_id = _seed_family_and_legs(db_session)

    result = plan_family_execution(family_id=family_id)
    assert result.legs_planned == 2
    assert result.duplicate_legs_skipped == 0

    count = db_session.execute(
        text("SELECT COUNT(*) FROM mock_executions WHERE family_id = CAST(:family_id AS uuid)"),
        {"family_id": family_id},
    ).scalar()
    assert count == 2


def test_mock_executor_is_idempotent(db_session):
    family_id = _seed_family_and_legs(db_session)

    first = plan_family_execution(family_id=family_id)
    second = plan_family_execution(family_id=family_id)

    assert first.legs_planned == 2
    assert second.legs_planned == 0
    assert second.duplicate_legs_skipped == 2
