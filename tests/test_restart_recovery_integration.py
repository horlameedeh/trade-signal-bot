import uuid

import pytest
from sqlalchemy import text

from app.db.session import SessionLocal
from app.services.restart_recovery import recover_after_restart


pytestmark = pytest.mark.integration


@pytest.fixture
def db_session():
    with SessionLocal() as db:
        try:
            db.execute(text("DELETE FROM execution_nodes WHERE name = 'restart-recovery-test-node' OR base_url = 'http://fake-node'"))
            db.execute(text("DELETE FROM control_actions WHERE payload->>'source' IN ('restart-recovery-test', 'alert_service')"))
            db.commit()
            yield db
        finally:
            db.rollback()
            db.execute(text("DELETE FROM execution_nodes WHERE name = 'restart-recovery-test-node' OR base_url = 'http://fake-node'"))
            db.execute(text("DELETE FROM control_actions WHERE payload->>'source' IN ('restart-recovery-test', 'alert_service')"))
            db.commit()


def _seed_family_leg_without_ticket(db_session) -> tuple[str, str]:
    account_id = str(uuid.uuid4())
    intent_id = str(uuid.uuid4())
    plan_id = str(uuid.uuid4())
    family_id = str(uuid.uuid4())
    leg_id = str(uuid.uuid4())
    source_msg_pk = str(uuid.uuid4())
    message_id = 990000 + (uuid.uuid4().int % 99999)

    db_session.execute(text("INSERT INTO symbols (canonical, asset_class) VALUES ('XAUUSD', 'metal') ON CONFLICT (canonical) DO NOTHING"))

    db_session.execute(
        text(
            """
            INSERT INTO broker_accounts (
              account_id, broker, platform, kind, label,
              allowed_providers, equity_start, equity_current, is_active
            )
            VALUES (
              CAST(:account_id AS uuid), 'ftmo', 'mt5', 'personal_live', 'restart-recovery-seed',
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
            VALUES (CAST(:source_msg_pk AS uuid), -1001239815745, :message_id, 'restart recovery seed', '{}'::jsonb)
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
              100, 90, ARRAY[110]::numeric(18,10)[], false, 'normal',
              false, false, false, false, 'restart recovery seed', '{}'::jsonb
            )
            """
        ),
        {
            "intent_id": intent_id,
            "source_msg_pk": source_msg_pk,
            "message_id": message_id,
            "dedupe_hash": f"restart-{source_msg_pk}",
        },
    )

    db_session.execute(
        text(
            """
            INSERT INTO trade_plans (plan_id, intent_id, account_id, policy_outcome, requires_approval, policy_reasons)
            VALUES (
              CAST(:plan_id AS uuid), CAST(:intent_id AS uuid), CAST(:account_id AS uuid),
              'allow', false, ARRAY['restart-recovery-seed']::text[]
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
              'XAUUSD', 'XAUUSD', 'buy', 100, 90, 1,
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

    db_session.execute(
        text(
            """
            INSERT INTO trade_legs (
              leg_id, family_id, plan_id, idx, leg_index, entry_price,
              requested_entry, sl_price, tp_price, lots, state, placement_delay_ms
            )
            VALUES (
              CAST(:leg_id AS uuid), CAST(:family_id AS uuid), CAST(:plan_id AS uuid),
              1, 1, 100, 100, 90, 110, 0.01, 'OPEN', 0
            )
            """
        ),
        {"leg_id": leg_id, "family_id": family_id, "plan_id": plan_id},
    )

    db_session.execute(
        text(
            """
            INSERT INTO execution_nodes (name, broker, platform, base_url, is_active, meta)
            VALUES ('restart-recovery-test-node', 'ftmo', 'mt5', 'http://fake-node', true, '{}'::jsonb)
            ON CONFLICT (broker, platform, name)
            DO UPDATE SET base_url=EXCLUDED.base_url, is_active=true
            """
        )
    )

    db_session.commit()
    return family_id, leg_id


def test_restart_recovery_reconciles_missing_ticket_and_syncs_state(monkeypatch, db_session):
    family_id, leg_id = _seed_family_leg_without_ticket(db_session)
    broker_ticket = f"REC-{leg_id[:8].upper()}"

    class FakeNode:
        def __init__(self, base_url):
            self.base_url = base_url

        def query_open_positions(self):
            return [
                {
                    "leg_id": leg_id,
                    "family_id": family_id,
                    "broker_ticket": broker_ticket,
                    "broker_symbol": "XAUUSD",
                    "side": "buy",
                    "lots": "0.01",
                    "open_price": "100",
                    "sl_price": "90",
                    "tp_price": "110",
                    "magic": 123456,
                    "comment": f"tradebot:{family_id}:{leg_id}",
                }
            ]

    monkeypatch.setattr("app.execution.reconciliation.HttpExecutionNode", FakeNode)
    monkeypatch.setattr("app.execution.state_sync.HttpExecutionNode", FakeNode)

    result = recover_after_restart(broker="ftmo", platform="mt5")

    assert result.reconciliation_positions_seen >= 1
    assert result.tickets_inserted == 1
    assert result.sync_positions_seen >= 1
    assert result.legs_confirmed_open >= 1
    assert result.families_recomputed >= 1
    assert result.alert_queued is True

    ticket = db_session.execute(
        text("SELECT broker_ticket FROM execution_tickets WHERE leg_id = CAST(:leg_id AS uuid)"),
        {"leg_id": leg_id},
    ).scalar()

    assert ticket == broker_ticket


def test_restart_recovery_is_idempotent(monkeypatch, db_session):
    family_id, leg_id = _seed_family_leg_without_ticket(db_session)
    broker_ticket = f"REC-{leg_id[:8].upper()}"

    class FakeNode:
        def __init__(self, base_url):
            self.base_url = base_url

        def query_open_positions(self):
            return [
                {
                    "leg_id": leg_id,
                    "family_id": family_id,
                    "broker_ticket": broker_ticket,
                    "broker_symbol": "XAUUSD",
                    "side": "buy",
                    "lots": "0.01",
                    "open_price": "100",
                    "sl_price": "90",
                    "tp_price": "110",
                    "magic": 123456,
                    "comment": f"tradebot:{family_id}:{leg_id}",
                }
            ]

    monkeypatch.setattr("app.execution.reconciliation.HttpExecutionNode", FakeNode)
    monkeypatch.setattr("app.execution.state_sync.HttpExecutionNode", FakeNode)

    first = recover_after_restart(broker="ftmo", platform="mt5", queue_alert=False)
    second = recover_after_restart(broker="ftmo", platform="mt5", queue_alert=False)

    assert first.tickets_inserted == 1
    assert second.tickets_inserted == 0
    assert second.tickets_updated >= 1

    count = db_session.execute(
        text("SELECT COUNT(*) FROM execution_tickets WHERE leg_id = CAST(:leg_id AS uuid)"),
        {"leg_id": leg_id},
    ).scalar()

    assert count == 1


def test_restart_recovery_reports_pending_queues(monkeypatch, db_session):
    family_id, leg_id = _seed_family_leg_without_ticket(db_session)

    db_session.execute(
        text(
            """
            INSERT INTO control_actions (action, status, payload)
            VALUES
              ('execution_retry', 'failed', jsonb_build_object('source', 'restart-recovery-test', 'family_id', CAST(:family_id AS text))),
              ('dead_letter:execution', 'queued', jsonb_build_object('source', 'restart-recovery-test', 'family_id', CAST(:family_id AS text)))
            """
        ),
        {"family_id": family_id},
    )
    db_session.commit()

    class FakeNode:
        def __init__(self, base_url):
            self.base_url = base_url

        def query_open_positions(self):
            return []

    monkeypatch.setattr("app.execution.reconciliation.HttpExecutionNode", FakeNode)
    monkeypatch.setattr("app.execution.state_sync.HttpExecutionNode", FakeNode)

    result = recover_after_restart(broker="ftmo", platform="mt5", queue_alert=False)

    assert result.pending_control_actions >= 2
    assert result.pending_execution_retries >= 1
    assert result.dead_letters >= 1
