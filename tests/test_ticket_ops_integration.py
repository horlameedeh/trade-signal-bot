import uuid

import pytest
from sqlalchemy import text

from app.db.session import SessionLocal
from app.execution.ticket_ops import close_legs_live, modify_legs_sl_tp_live


pytestmark = pytest.mark.integration


@pytest.fixture
def db_session():
    with SessionLocal() as db:
        try:
            yield db
        finally:
            db.rollback()


def _seed_ticket(db_session) -> str:
    account_id = str(uuid.uuid4())
    intent_id = str(uuid.uuid4())
    plan_id = str(uuid.uuid4())
    family_id = str(uuid.uuid4())
    leg_id = str(uuid.uuid4())
    source_msg_pk = str(uuid.uuid4())
    source_message_id = 900000 + (uuid.UUID(source_msg_pk).int % 99999)

    # execution_node required by ticket_ops (get_active_execution_node)
    db_session.execute(
        text(
            """
            INSERT INTO execution_nodes (name, broker, platform, base_url, is_active, meta)
            VALUES ('test-node-stub', 'ftmo', 'mt5', 'http://fake-node', true, '{}'::jsonb)
            ON CONFLICT (broker, platform, name)
            DO UPDATE SET base_url = EXCLUDED.base_url, is_active = true
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
              CAST(:account_id AS uuid), 'ftmo', 'mt5', 'personal_live', 'seed-ticket-ops',
              ARRAY[]::provider_code[], 10000, true
            )
            """
        ),
        {"account_id": account_id},
    )

    db_session.execute(
        text(
            """
            INSERT INTO telegram_chats (chat_id, provider_code)
            VALUES (-1009999999999, 'fredtrading')
            ON CONFLICT (chat_id) DO UPDATE SET provider_code = 'fredtrading'
            """
        )
    )

    db_session.execute(
        text(
            """
            INSERT INTO telegram_messages (msg_pk, chat_id, message_id, text, raw_json)
            VALUES (CAST(:source_msg_pk AS uuid), -1009999999999, :source_message_id, 'seed', '{}'::jsonb)
            ON CONFLICT DO NOTHING
            """
        ),
        {"source_msg_pk": source_msg_pk, "source_message_id": source_message_id},
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
              CAST(:intent_id AS uuid), 'fredtrading', -1009999999999, CAST(:source_msg_pk AS uuid),
              :source_message_id, :dedupe_hash, 0.95, 'XAUUSD', 'XAUUSD', 'buy', 'market',
              4662, 4527, ARRAY[4690]::numeric(18,10)[], false, 'normal',
              false, false, false, false, 'seed', '{}'::jsonb
            )
            """
        ),
        {
            "intent_id": intent_id,
            "source_msg_pk": source_msg_pk,
            "source_message_id": source_message_id,
            "dedupe_hash": f"seed-ticket-ops-{source_msg_pk}",
        },
    )

    db_session.execute(
        text(
            """
            INSERT INTO trade_plans (plan_id, intent_id, account_id, policy_outcome, requires_approval, policy_reasons)
            VALUES (CAST(:plan_id AS uuid), CAST(:intent_id AS uuid), CAST(:account_id AS uuid), 'allow', false, ARRAY['seed']::text[])
            """
        ),
        {"plan_id": plan_id, "intent_id": intent_id, "account_id": account_id},
    )

    db_session.execute(
        text(
            """
            INSERT INTO trade_families (
              family_id, intent_id, plan_id, provider, account_id, chat_id, source_msg_pk,
              symbol_canonical, side, entry_price, sl_price, tp_count, state, is_stub,
              management_rules, meta
            )
            VALUES (
              CAST(:family_id AS uuid), CAST(:intent_id AS uuid), CAST(:plan_id AS uuid),
              'fredtrading', CAST(:account_id AS uuid), -1009999999999, CAST(:source_msg_pk AS uuid),
              'XAUUSD', 'buy', 4662, 4527, 1, 'OPEN', false, '{}'::jsonb, '{}'::jsonb
            )
            """
        ),
        {"family_id": family_id, "intent_id": intent_id, "plan_id": plan_id,
         "account_id": account_id, "source_msg_pk": source_msg_pk},
    )

    db_session.execute(
        text(
            """
            INSERT INTO trade_legs (leg_id, family_id, plan_id, idx, leg_index, entry_price,
              sl_price, tp_price, lots, state)
            VALUES (CAST(:leg_id AS uuid), CAST(:family_id AS uuid), CAST(:plan_id AS uuid),
              1, 1, 4662, 4527, 4690, 0.01, 'OPEN')
            """
        ),
        {"leg_id": leg_id, "family_id": family_id, "plan_id": plan_id},
    )

    broker_ticket = f"T{uuid.uuid4().hex[:10].upper()}"

    db_session.execute(
        text(
            """
            INSERT INTO execution_tickets (
              leg_id, family_id, broker, platform, broker_symbol, broker_ticket,
              side, order_type, requested_entry, actual_fill_price,
              sl_price, tp_price, lots, status, raw_response
            )
            VALUES (
              CAST(:leg_id AS uuid), CAST(:family_id AS uuid), 'ftmo', 'mt5', 'XAUUSD', :broker_ticket,
              'buy', 'market', 4662, 4662, 4527, 4690, 0.01, 'open', '{}'::jsonb
            )
            """
        ),
        {"leg_id": leg_id, "family_id": family_id, "broker_ticket": broker_ticket},
    )

    db_session.commit()
    return leg_id


def test_modify_legs_sl_tp_live_updates_ticket(monkeypatch, db_session):
    leg_id = _seed_ticket(db_session)

    class FakeNode:
        def __init__(self, base_url):
            self.base_url = base_url

        def modify_ticket_sl_tp(self, payload):
            assert payload[0]["broker_ticket"]  # non-empty ticket passed through
            return [{"leg_id": payload[0]["leg_id"], "ok": True, "status": "modified"}]

    monkeypatch.setattr("app.execution.ticket_ops.HttpExecutionNode", FakeNode)

    result = modify_legs_sl_tp_live(leg_ids=[leg_id], sl="4662", tp="4701")

    assert result.ok == 1
    row = db_session.execute(
        text("SELECT sl_price::text, tp_price::text FROM execution_tickets WHERE leg_id = CAST(:leg_id AS uuid)"),
        {"leg_id": leg_id},
    ).mappings().first()

    assert row["sl_price"] == "4662.0000000000"
    assert row["tp_price"] == "4701.0000000000"


def test_close_legs_live_marks_ticket_closed(monkeypatch, db_session):
    leg_id = _seed_ticket(db_session)

    class FakeNode:
        def __init__(self, base_url):
            self.base_url = base_url

        def close_tickets(self, payload):
            assert payload[0]["broker_ticket"]  # non-empty ticket passed through
            return [{"leg_id": payload[0]["leg_id"], "ok": True, "status": "closed"}]

    monkeypatch.setattr("app.execution.ticket_ops.HttpExecutionNode", FakeNode)

    result = close_legs_live(leg_ids=[leg_id])

    assert result.ok == 1
    status = db_session.execute(
        text("SELECT status FROM execution_tickets WHERE leg_id = CAST(:leg_id AS uuid)"),
        {"leg_id": leg_id},
    ).scalar()

    assert status == "closed"
