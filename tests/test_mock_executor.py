import uuid

import pytest
from sqlalchemy import text

from app.db.session import SessionLocal
from app.execution.mock_executor import plan_family_execution


pytestmark = pytest.mark.integration


@pytest.fixture
def db_session():
    with SessionLocal() as db:
        try:
            yield db
        finally:
            db.rollback()


def _seed_family_and_legs(db_session):
    family_id = str(uuid.uuid4())
    plan_id = str(uuid.uuid4())
    source_msg_pk = str(uuid.uuid4())
    intent_id = db_session.execute(
        text("SELECT intent_id FROM trade_intents ORDER BY created_at DESC LIMIT 1")
    ).scalar()
    account_id = db_session.execute(
        text("SELECT account_id FROM broker_accounts WHERE is_active = true LIMIT 1")
    ).scalar()
    if intent_id is None:
        raise RuntimeError("No rows in trade_intents; cannot seed trade_families for integration test")
    if account_id is None:
        raise RuntimeError("No active broker account; cannot seed trade_plans for integration test")

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
        {"plan_id": plan_id, "intent_id": str(intent_id), "account_id": str(account_id)},
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
              NULL,
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
        {"family_id": family_id, "source_msg_pk": source_msg_pk, "intent_id": str(intent_id)},
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
