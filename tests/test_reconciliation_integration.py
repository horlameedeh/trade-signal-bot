import uuid

import pytest
from sqlalchemy import text

from app.db.session import SessionLocal
from app.execution.reconciliation import reconcile_open_positions


pytestmark = pytest.mark.integration


@pytest.fixture
def db_session():
    with SessionLocal() as db:
        # Clean up execution records before test to ensure isolation
        db.execute(text("DELETE FROM execution_tickets"))
        db.execute(text("DELETE FROM execution_nodes"))
        db.commit()
        try:
            yield db
        finally:
            # Clean up after test
            db.execute(text("DELETE FROM execution_tickets"))
            db.execute(text("DELETE FROM execution_nodes"))
            db.commit()


def _seed_family_leg(db_session) -> tuple[str, str]:
    account_id = str(uuid.uuid4())
    intent_id = str(uuid.uuid4())
    plan_id = str(uuid.uuid4())
    family_id = str(uuid.uuid4())
    leg_id = str(uuid.uuid4())
    source_msg_pk = str(uuid.uuid4())

    db_session.execute(
        text(
            """
            INSERT INTO symbols (canonical, asset_class)
            VALUES ('XAUUSD', 'metal')
            ON CONFLICT (canonical) DO NOTHING
            """
        )
    )

    db_session.execute(
        text(
            """
            INSERT INTO broker_accounts (
              account_id, broker, platform, kind, label,
              allowed_providers, equity_start, is_active
            )
            VALUES (
              CAST(:account_id AS uuid),
              'ftmo',
              'mt5',
              'personal_live',
              'reconcile-seed',
              ARRAY[]::provider_code[],
              10000,
              true
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
            VALUES (CAST(:source_msg_pk AS uuid), -1001239815745, :message_id, 'seed', '{}'::jsonb)
            ON CONFLICT DO NOTHING
            """
        ),
        {"source_msg_pk": source_msg_pk, "message_id": 850000 + (uuid.uuid4().int % 99999)},
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
              4662, 4527, ARRAY[4690]::numeric(18,10)[], false, 'normal',
              false, false, false, false, 'seed', '{}'::jsonb
            )
            """
        ),
        {
            "intent_id": intent_id,
            "source_msg_pk": source_msg_pk,
            "message_id": 850000 + (uuid.uuid4().int % 99999),
            "dedupe_hash": f"seed-{source_msg_pk}",
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
              family_id, intent_id, plan_id, provider, account_id, chat_id, source_msg_pk,
              symbol_canonical, broker_symbol, side, entry_price, sl_price, tp_count,
              state, is_stub, management_rules, meta
            )
            VALUES (
              CAST(:family_id AS uuid),
              CAST(:intent_id AS uuid),
              CAST(:plan_id AS uuid),
              'fredtrading',
              CAST(:account_id AS uuid),
              -1001239815745,
              CAST(:source_msg_pk AS uuid),
              'XAUUSD',
              'XAUUSD',
              'buy',
              4662,
              4527,
              1,
              'OPEN',
              false,
              '{}'::jsonb,
              '{}'::jsonb
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
              CAST(:leg_id AS uuid),
              CAST(:family_id AS uuid),
              CAST(:plan_id AS uuid),
              1,
              1,
              4662,
              4662,
              4527,
              4690,
              0.01,
              'OPEN',
              0
            )
            """
        ),
        {"leg_id": leg_id, "family_id": family_id, "plan_id": plan_id},
    )

    db_session.commit()
    return family_id, leg_id


def _seed_node(db_session):
    db_session.execute(
        text(
            """
            INSERT INTO execution_nodes (name, broker, platform, base_url, is_active, meta)
            VALUES ('reconcile-test-node', 'ftmo', 'mt5', 'http://fake-node', true, '{}'::jsonb)
            ON CONFLICT (broker, platform, name)
            DO UPDATE SET base_url=EXCLUDED.base_url, is_active=true
            """
        )
    )
    db_session.commit()


def test_reconciliation_inserts_missing_ticket(monkeypatch, db_session):
    family_id, leg_id = _seed_family_leg(db_session)
    _seed_node(db_session)

    class FakeNode:
        def __init__(self, base_url):
            self.base_url = base_url

        def query_open_positions(self):
            return [
                {
                    "leg_id": leg_id,
                    "family_id": family_id,
                    "broker_ticket": "777001",
                    "broker_symbol": "XAUUSD",
                    "side": "buy",
                    "lots": "0.01",
                    "open_price": "4662",
                    "sl_price": "4527",
                    "tp_price": "4690",
                    "magic": 123456,
                    "comment": f"tradebot:{family_id}:{leg_id}",
                }
            ]

    monkeypatch.setattr("app.execution.reconciliation.HttpExecutionNode", FakeNode)

    result = reconcile_open_positions(broker="ftmo", platform="mt5")

    assert result.positions_seen >= 1
    assert result.tickets_inserted == 1

    ticket = db_session.execute(
        text("SELECT broker_ticket FROM execution_tickets WHERE leg_id = CAST(:leg_id AS uuid)"),
        {"leg_id": leg_id},
    ).scalar()

    assert ticket == "777001"


def test_reconciliation_updates_existing_ticket(monkeypatch, db_session):
    family_id, leg_id = _seed_family_leg(db_session)
    _seed_node(db_session)

    db_session.execute(
        text(
            """
            INSERT INTO execution_tickets (
              leg_id, family_id, broker, platform, broker_symbol, broker_ticket,
              side, order_type, requested_entry, actual_fill_price,
              sl_price, tp_price, lots, status, raw_response
            )
            VALUES (
              CAST(:leg_id AS uuid), CAST(:family_id AS uuid), 'ftmo', 'mt5', 'XAUUSD', 'OLD',
              'buy', 'market', 4662, 4662,
              4527, 4690, 0.01, 'open', '{}'::jsonb
            )
            """
        ),
        {"leg_id": leg_id, "family_id": family_id},
    )
    db_session.commit()

    class FakeNode:
        def __init__(self, base_url):
            self.base_url = base_url

        def query_open_positions(self):
            return [
                {
                    "leg_id": leg_id,
                    "family_id": family_id,
                    "broker_ticket": "NEW777",
                    "broker_symbol": "XAUUSD",
                    "side": "buy",
                    "lots": "0.01",
                    "open_price": "4663",
                    "sl_price": "4662",
                    "tp_price": "4701",
                    "magic": 123456,
                    "comment": f"tradebot:{family_id}:{leg_id}",
                }
            ]

    monkeypatch.setattr("app.execution.reconciliation.HttpExecutionNode", FakeNode)

    result = reconcile_open_positions(broker="ftmo", platform="mt5")

    assert result.tickets_updated == 1

    row = db_session.execute(
        text(
            """
            SELECT broker_ticket, actual_fill_price::text, sl_price::text, tp_price::text
            FROM execution_tickets
            WHERE leg_id = CAST(:leg_id AS uuid)
            """
        ),
        {"leg_id": leg_id},
    ).mappings().first()

    assert row["broker_ticket"] == "NEW777"
    assert row["actual_fill_price"] == "4663.0000000000"
    assert row["sl_price"] == "4662.0000000000"
    assert row["tp_price"] == "4701.0000000000"


def test_reconciliation_ignores_unmatched_positions(monkeypatch, db_session):
    _seed_node(db_session)

    class FakeNode:
        def __init__(self, base_url):
            self.base_url = base_url

        def query_open_positions(self):
            return [
                {
                    "broker_ticket": "NOPE",
                    "broker_symbol": "XAUUSD",
                    "side": "buy",
                    "lots": "0.01",
                    "comment": "manual-position",
                }
            ]

    monkeypatch.setattr("app.execution.reconciliation.HttpExecutionNode", FakeNode)

    result = reconcile_open_positions(broker="ftmo", platform="mt5")

    assert result.unmatched_positions >= 1
