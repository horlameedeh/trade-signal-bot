import uuid

import pytest
from sqlalchemy import text

from app.db.session import SessionLocal
from app.services.autonomous_execution import find_executable_families, process_autonomous_executions


pytestmark = pytest.mark.integration


@pytest.fixture
def db_session():
    with SessionLocal() as db:
        try:
            yield db
        finally:
            db.rollback()


def _seed_family(db_session, *, with_ticket: bool = False) -> str:
    account_id = str(uuid.uuid4())
    intent_id = str(uuid.uuid4())
    plan_id = str(uuid.uuid4())
    family_id = str(uuid.uuid4())
    source_msg_pk = str(uuid.uuid4())
    message_id = 1300000 + (uuid.uuid4().int % 99999)

    db_session.execute(text("INSERT INTO symbols (canonical, asset_class) VALUES ('XAUUSD', 'metal') ON CONFLICT (canonical) DO NOTHING"))

    db_session.execute(
        text(
            """
            INSERT INTO broker_accounts (
              account_id, broker, platform, kind, label,
              allowed_providers, equity_start, equity_current, is_active
            )
            VALUES (
              CAST(:account_id AS uuid), 'ftmo', 'mt5', 'personal_live', 'autonomous-exec-seed',
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
            VALUES (CAST(:source_msg_pk AS uuid), -1001239815745, :message_id, 'autonomous exec seed', '{}'::jsonb)
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
              100, 90, ARRAY[110,120]::numeric(18,10)[], false, 'normal',
              false, false, false, false, 'autonomous exec seed', '{}'::jsonb
            )
            """
        ),
        {
            "intent_id": intent_id,
            "source_msg_pk": source_msg_pk,
            "message_id": message_id,
            "dedupe_hash": f"autonomous-exec-{source_msg_pk}",
        },
    )

    db_session.execute(
        text(
            """
            INSERT INTO trade_plans (plan_id, intent_id, account_id, policy_outcome, requires_approval, policy_reasons)
            VALUES (
              CAST(:plan_id AS uuid), CAST(:intent_id AS uuid), CAST(:account_id AS uuid),
              'allow', false, ARRAY['autonomous-exec-seed']::text[]
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
              'XAUUSD', 'XAUUSD', 'buy', 100, 90, 2,
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
        },
    )

    leg_ids = []
    for idx in [1, 2]:
        leg_id = str(uuid.uuid4())
        leg_ids.append(leg_id)
        db_session.execute(
            text(
                """
                INSERT INTO trade_legs (
                  leg_id, family_id, plan_id, idx, leg_index, entry_price,
                  requested_entry, sl_price, tp_price, lots, state, placement_delay_ms
                )
                VALUES (
                  CAST(:leg_id AS uuid), CAST(:family_id AS uuid), CAST(:plan_id AS uuid),
                  :idx, :idx, 100, 100, 90, :tp, 0.01, 'OPEN', 0
                )
                """
            ),
            {"leg_id": leg_id, "family_id": family_id, "plan_id": plan_id, "idx": idx, "tp": 100 + idx * 10},
        )

    if with_ticket:
        db_session.execute(
            text(
                """
                INSERT INTO execution_tickets (
                  leg_id, family_id, broker, platform, broker_symbol, broker_ticket,
                  side, order_type, requested_entry, actual_fill_price,
                  sl_price, tp_price, lots, status, raw_response
                )
                VALUES (
                  CAST(:leg_id AS uuid), CAST(:family_id AS uuid), 'ftmo', 'mt5', 'XAUUSD', :ticket,
                  'buy', 'market', 100, 100, 90, 110, 0.01, 'open', '{}'::jsonb
                )
                """
            ),
            {"leg_id": leg_ids[0], "family_id": family_id, "ticket": f"AUTO-{uuid.uuid4().hex[:8]}"},
        )

    db_session.commit()
    return family_id


def test_find_executable_families_skips_already_ticketed(db_session):
    executable = _seed_family(db_session, with_ticket=False)
    _seed_family(db_session, with_ticket=True)

    found = find_executable_families(broker="ftmo", platform="mt5", limit=20)

    assert executable in found


def test_process_autonomous_executions_counts_results(monkeypatch, db_session):
    family_id = _seed_family(db_session, with_ticket=False)

    class FakeNodeRow:
        base_url = "http://fake-node"

    class FakeResult:
        sent = 2

    class FakeGuarded:
        blocked = False
        requires_approval = False
        execution_result = FakeResult()

    monkeypatch.setattr("app.services.autonomous_execution.get_active_execution_node", lambda broker, platform: FakeNodeRow())
    monkeypatch.setattr("app.services.autonomous_execution.HttpExecutionNode", lambda base_url: object())
    monkeypatch.setattr("app.services.autonomous_execution.execute_family_with_prop_guard", lambda family_id, adapter: FakeGuarded())

    result = process_autonomous_executions(broker="ftmo", platform="mt5", limit=20)

    assert result.families_seen >= 1
    assert result.attempted >= 1
    assert result.executed >= 1


def test_process_autonomous_executions_records_blocked(monkeypatch, db_session):
    _seed_family(db_session, with_ticket=False)

    class FakeNodeRow:
        base_url = "http://fake-node"

    class FakeGuarded:
        blocked = True
        requires_approval = False
        execution_result = None

    monkeypatch.setattr("app.services.autonomous_execution.get_active_execution_node", lambda broker, platform: FakeNodeRow())
    monkeypatch.setattr("app.services.autonomous_execution.HttpExecutionNode", lambda base_url: object())
    monkeypatch.setattr("app.services.autonomous_execution.execute_family_with_prop_guard", lambda family_id, adapter: FakeGuarded())

    result = process_autonomous_executions(broker="ftmo", platform="mt5", limit=20)

    assert result.blocked >= 1
def test_find_executable_families_skips_telethon_dry_run_family(db_session):
    family_id = _seed_family(db_session, with_ticket=False)

    db_session.execute(
        text(
            """
            UPDATE telegram_messages tm
            SET raw_json = jsonb_build_object(
                'source', 'telethon_ingestion',
                'dry_run', true
            )
            FROM trade_families tf
            WHERE tf.source_msg_pk = tm.msg_pk
              AND tf.family_id = CAST(:family_id AS uuid)
            """
        ),
        {"family_id": family_id},
    )
    db_session.commit()

    found = find_executable_families(broker="ftmo", platform="mt5", limit=20)

    assert family_id not in found
