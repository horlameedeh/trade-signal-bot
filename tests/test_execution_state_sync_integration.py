import uuid

import pytest
from sqlalchemy import text

from app.db.session import SessionLocal
from app.execution.state_sync import sync_execution_state


pytestmark = pytest.mark.integration


@pytest.fixture
def db_session():
    with SessionLocal() as db:
        db.execute(text("DELETE FROM execution_tickets"))
        db.execute(text("DELETE FROM execution_nodes WHERE name = 'state-sync-test-node'"))
        db.execute(text("DELETE FROM trade_legs"))
        db.execute(text("DELETE FROM trade_families"))
        db.execute(text("DELETE FROM trade_plans"))
        db.execute(text("DELETE FROM trade_intents"))
        db.execute(text("DELETE FROM provider_account_routes"))
        db.execute(text("DELETE FROM broker_accounts WHERE label = 'sync-seed'"))
        db.commit()
        try:
            yield db
        finally:
            db.execute(text("DELETE FROM execution_tickets"))
            db.execute(text("DELETE FROM execution_nodes WHERE name = 'state-sync-test-node'"))
            db.execute(text("DELETE FROM trade_legs"))
            db.execute(text("DELETE FROM trade_families"))
            db.execute(text("DELETE FROM trade_plans"))
            db.execute(text("DELETE FROM trade_intents"))
            db.execute(text("DELETE FROM provider_account_routes"))
            db.execute(text("DELETE FROM broker_accounts WHERE label = 'sync-seed'"))
            db.commit()


def _seed_open_ticket(db_session, *, broker: str = "ftmo", platform: str = "mt5") -> tuple[str, str, str]:
    account_id = str(uuid.uuid4())
    intent_id = str(uuid.uuid4())
    plan_id = str(uuid.uuid4())
    family_id = str(uuid.uuid4())
    leg_id = str(uuid.uuid4())
    source_msg_pk = str(uuid.uuid4())
    broker_ticket = str(900000 + (uuid.uuid4().int % 99999))
    message_id = 930000 + (uuid.uuid4().int % 99999)

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
              CAST(:account_id AS uuid), :broker, :platform, 'personal_live', 'sync-seed',
              ARRAY[]::provider_code[], 10000, 10000, true
            )
            """
        ),
        {"account_id": account_id, "broker": broker, "platform": platform},
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
            VALUES (CAST(:source_msg_pk AS uuid), -1001239815745, :message_id, 'sync seed', '{}'::jsonb)
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
              4662, 4527, ARRAY[4690]::numeric(18,10)[], false, 'normal',
              false, false, false, false, 'sync seed', '{}'::jsonb
            )
            """
        ),
        {
            "intent_id": intent_id,
            "source_msg_pk": source_msg_pk,
            "message_id": message_id,
            "dedupe_hash": f"sync-{source_msg_pk}",
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
              ARRAY['sync-seed']::text[]
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
              'XAUUSD', 'XAUUSD', 'buy', 4662, 4527, 1,
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
              1, 1, 4662, 4662, 4527, 4690, 0.01, 'OPEN', 0
            )
            """
        ),
        {"leg_id": leg_id, "family_id": family_id, "plan_id": plan_id},
    )

    db_session.execute(
        text(
            """
            INSERT INTO execution_tickets (
              leg_id, family_id, broker, platform, broker_symbol, broker_ticket,
              side, order_type, requested_entry, actual_fill_price,
              sl_price, tp_price, lots, status, raw_response
            )
            VALUES (
              CAST(:leg_id AS uuid), CAST(:family_id AS uuid), :broker, :platform, 'XAUUSD', :broker_ticket,
              'buy', 'market', 4662, 4662,
              4527, 4690, 0.01, 'open', '{}'::jsonb
            )
            """
        ),
        {"leg_id": leg_id, "family_id": family_id, "broker": broker, "platform": platform, "broker_ticket": broker_ticket},
    )

    db_session.execute(
        text(
            """
            INSERT INTO execution_nodes (name, broker, platform, base_url, is_active, meta)
            VALUES ('state-sync-test-node', :broker, :platform, 'http://fake-node', true, '{}'::jsonb)
            ON CONFLICT (broker, platform, name)
            DO UPDATE SET base_url = EXCLUDED.base_url, is_active = true
            """
        ),
        {"broker": broker, "platform": platform},
    )

    db_session.commit()
    return family_id, leg_id, broker_ticket


def test_sync_confirms_open_ticket(monkeypatch, db_session):
    family_id, leg_id, broker_ticket = _seed_open_ticket(db_session)

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
                    "open_price": "4663",
                    "sl_price": "4528",
                    "tp_price": "4691",
                    "magic": 123456,
                    "comment": f"tradebot:{family_id}:{leg_id}",
                }
            ]

    monkeypatch.setattr("app.execution.state_sync.HttpExecutionNode", FakeNode)

    result = sync_execution_state(broker="ftmo", platform="mt5")

    assert result.legs_confirmed_open >= 1
    assert result.tickets_updated >= 1

    row = db_session.execute(
        text(
            """
            SELECT actual_fill_price::text, sl_price::text, tp_price::text, status
            FROM execution_tickets
            WHERE leg_id = CAST(:leg_id AS uuid)
            """
        ),
        {"leg_id": leg_id},
    ).mappings().first()

    assert row["status"] == "open"
    assert row["actual_fill_price"] == "4663.0000000000"
    assert row["sl_price"] == "4528.0000000000"
    assert row["tp_price"] == "4691.0000000000"


def test_sync_marks_missing_open_ticket_closed(monkeypatch, db_session):
    family_id, leg_id, broker_ticket = _seed_open_ticket(db_session)

    class FakeNode:
        def __init__(self, base_url):
            self.base_url = base_url

        def query_open_positions(self):
            return []

    monkeypatch.setattr("app.execution.state_sync.HttpExecutionNode", FakeNode)

    result = sync_execution_state(broker="ftmo", platform="mt5")

    assert result.legs_marked_closed >= 1
    assert result.manual_or_broker_closed >= 1

    row = db_session.execute(
        text(
            """
            SELECT et.status, tl.state, tf.state
            FROM execution_tickets et
            JOIN trade_legs tl ON tl.leg_id = et.leg_id
            JOIN trade_families tf ON tf.family_id = et.family_id
            WHERE et.leg_id = CAST(:leg_id AS uuid)
            """
        ),
        {"leg_id": leg_id},
    ).mappings().first()

    assert row["status"] == "closed"
    assert row["state"] == "CLOSED"


def test_sync_rolls_family_to_partially_closed(monkeypatch, db_session):
    family_id, leg_id, broker_ticket = _seed_open_ticket(db_session)

    # Add second open leg/ticket that remains open at broker.
    second_leg_id = str(uuid.uuid4())
    second_ticket = "TICKET2"

    plan_id = db_session.execute(
        text("SELECT plan_id::text FROM trade_legs WHERE leg_id = CAST(:leg_id AS uuid)"),
        {"leg_id": leg_id},
    ).scalar()

    db_session.execute(
        text(
            """
            INSERT INTO trade_legs (
              leg_id, family_id, plan_id, idx, leg_index, entry_price,
              requested_entry, sl_price, tp_price, lots, state, placement_delay_ms
            )
            VALUES (
              CAST(:leg_id AS uuid), CAST(:family_id AS uuid), CAST(:plan_id AS uuid),
              2, 2, 4662, 4662, 4527, 4700, 0.01, 'OPEN', 0
            )
            """
        ),
        {"leg_id": second_leg_id, "family_id": family_id, "plan_id": plan_id},
    )

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
              'buy', 'market', 4662, 4662,
              4527, 4700, 0.01, 'open', '{}'::jsonb
            )
            """
        ),
        {"leg_id": second_leg_id, "family_id": family_id, "broker_ticket": second_ticket},
    )
    db_session.commit()

    class FakeNode:
        def __init__(self, base_url):
            self.base_url = base_url

        def query_open_positions(self):
            return [
                {
                    "leg_id": second_leg_id,
                    "family_id": family_id,
                    "broker_ticket": second_ticket,
                    "broker_symbol": "XAUUSD",
                    "side": "buy",
                    "lots": "0.01",
                    "open_price": "4662",
                    "sl_price": "4527",
                    "tp_price": "4700",
                    "magic": 123456,
                    "comment": f"tradebot:{family_id}:{second_leg_id}",
                }
            ]

    monkeypatch.setattr("app.execution.state_sync.HttpExecutionNode", FakeNode)

    sync_execution_state(broker="ftmo", platform="mt5")

    family_state = db_session.execute(
        text("SELECT state FROM trade_families WHERE family_id = CAST(:family_id AS uuid)"),
        {"family_id": family_id},
    ).scalar()

    assert family_state == "PARTIALLY_CLOSED"


def test_sync_classifies_missing_buy_position_as_tp_hit(monkeypatch, db_session):
    family_id, leg_id, broker_ticket = _seed_open_ticket(db_session)

    db_session.execute(
        text(
            """
            UPDATE execution_tickets
            SET actual_fill_price = 4690,
                sl_price = 4527,
                tp_price = 4690,
                side = 'buy'
            WHERE leg_id = CAST(:leg_id AS uuid)
            """
        ),
        {"leg_id": leg_id},
    )
    db_session.commit()

    class FakeNode:
        def __init__(self, base_url):
            self.base_url = base_url

        def query_open_positions(self):
            return []

    monkeypatch.setattr("app.execution.state_sync.HttpExecutionNode", FakeNode)

    sync_execution_state(broker="ftmo", platform="mt5")

    state = db_session.execute(
        text("SELECT state FROM trade_legs WHERE leg_id = CAST(:leg_id AS uuid)"),
        {"leg_id": leg_id},
    ).scalar()

    assert state == "TP_HIT"


def test_sync_classifies_missing_buy_position_as_sl_hit(monkeypatch, db_session):
    family_id, leg_id, broker_ticket = _seed_open_ticket(db_session)

    db_session.execute(
        text(
            """
            UPDATE execution_tickets
            SET actual_fill_price = 4527,
                sl_price = 4527,
                tp_price = 4690,
                side = 'buy'
            WHERE leg_id = CAST(:leg_id AS uuid)
            """
        ),
        {"leg_id": leg_id},
    )
    db_session.commit()

    class FakeNode:
        def __init__(self, base_url):
            self.base_url = base_url

        def query_open_positions(self):
            return []

    monkeypatch.setattr("app.execution.state_sync.HttpExecutionNode", FakeNode)

    sync_execution_state(broker="ftmo", platform="mt5")

    state = db_session.execute(
        text("SELECT state FROM trade_legs WHERE leg_id = CAST(:leg_id AS uuid)"),
        {"leg_id": leg_id},
    ).scalar()

    assert state == "SL_HIT"


def test_sync_classifies_missing_position_as_manual_when_price_not_at_sl_or_tp(monkeypatch, db_session):
    family_id, leg_id, broker_ticket = _seed_open_ticket(db_session)

    db_session.execute(
        text(
            """
            UPDATE execution_tickets
            SET actual_fill_price = 4600,
                sl_price = 4527,
                tp_price = 4690,
                side = 'buy'
            WHERE leg_id = CAST(:leg_id AS uuid)
            """
        ),
        {"leg_id": leg_id},
    )
    db_session.commit()

    class FakeNode:
        def __init__(self, base_url):
            self.base_url = base_url

        def query_open_positions(self):
            return []

    monkeypatch.setattr("app.execution.state_sync.HttpExecutionNode", FakeNode)

    sync_execution_state(broker="ftmo", platform="mt5")

    state = db_session.execute(
        text("SELECT state FROM trade_legs WHERE leg_id = CAST(:leg_id AS uuid)"),
        {"leg_id": leg_id},
    ).scalar()

    assert state == "CLOSED_MANUAL"


def test_sync_recomputes_lifecycle_meta_for_affected_family(monkeypatch, db_session):
    family_id, leg_id, broker_ticket = _seed_open_ticket(db_session)

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
                    "open_price": "4663",
                    "sl_price": "4528",
                    "tp_price": "4691",
                    "magic": 123456,
                    "comment": f"tradebot:{family_id}:{leg_id}",
                }
            ]

    monkeypatch.setattr("app.execution.state_sync.HttpExecutionNode", FakeNode)

    result = sync_execution_state(broker="ftmo", platform="mt5")

    assert result.families_recomputed >= 1

    row = db_session.execute(
        text(
            """
            SELECT meta->'lifecycle' AS lifecycle
            FROM trade_families
            WHERE family_id = CAST(:family_id AS uuid)
            """
        ),
        {"family_id": family_id},
    ).mappings().first()

    assert row["lifecycle"] is not None
    assert row["lifecycle"]["legs_total"] == 1
    assert row["lifecycle"]["legs_open"] == 1


def test_sync_recomputes_lifecycle_after_position_closes(monkeypatch, db_session):
    family_id, leg_id, broker_ticket = _seed_open_ticket(db_session)

    db_session.execute(
        text(
            """
            UPDATE execution_tickets
            SET actual_fill_price = 4690,
                sl_price = 4527,
                tp_price = 4690,
                side = 'buy'
            WHERE leg_id = CAST(:leg_id AS uuid)
            """
        ),
        {"leg_id": leg_id},
    )
    db_session.commit()

    class FakeNode:
        def __init__(self, base_url):
            self.base_url = base_url

        def query_open_positions(self):
            return []

    monkeypatch.setattr("app.execution.state_sync.HttpExecutionNode", FakeNode)

    result = sync_execution_state(broker="ftmo", platform="mt5")

    assert result.families_recomputed >= 1

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

    assert row["state"] == "CLOSED"
    assert row["lifecycle"]["legs_closed"] == 1
    assert row["lifecycle"]["legs_open"] == 0


def test_sync_triggers_live_be_at_tp1_after_tp1_hit(monkeypatch, db_session):
    family_id, leg_id, broker_ticket = _seed_open_ticket(db_session)

    # Add BE rule and a second open leg that should be modified.
    second_leg_id = str(uuid.uuid4())
    second_ticket = f"AUTO-{uuid.uuid4().hex[:8]}"

    plan_id = db_session.execute(
        text("SELECT plan_id::text FROM trade_legs WHERE leg_id = CAST(:leg_id AS uuid)"),
        {"leg_id": leg_id},
    ).scalar()

    db_session.execute(
        text(
            """
            UPDATE trade_families
            SET management_rules = '{"BE_AT_TP1": true, "SL_TO_ENTRY_AT_TP1": true}'::jsonb,
                entry_price = 4662
            WHERE family_id = CAST(:family_id AS uuid)
            """
        ),
        {"family_id": family_id},
    )

    db_session.execute(
        text(
            """
            UPDATE trade_legs
            SET leg_index = 1,
                idx = 1,
                actual_fill_price = NULL
            WHERE leg_id = CAST(:leg_id AS uuid)
            """
        ),
        {"leg_id": leg_id},
    )

    db_session.execute(
        text(
            """
            UPDATE execution_tickets
            SET actual_fill_price = 4690,
                sl_price = 4527,
                tp_price = 4690,
                side = 'buy'
            WHERE leg_id = CAST(:leg_id AS uuid)
            """
        ),
        {"leg_id": leg_id},
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
              2, 2, 4662, 4662, 4527, 4700, 0.01, 'OPEN', 0
            )
            """
        ),
        {"leg_id": second_leg_id, "family_id": family_id, "plan_id": plan_id},
    )

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
              'buy', 'market', 4662, 4662,
              4527, 4700, 0.01, 'open', '{}'::jsonb
            )
            """
        ),
        {"leg_id": second_leg_id, "family_id": family_id, "ticket": second_ticket},
    )
    db_session.commit()

    class FakeNode:
        def __init__(self, base_url):
            self.base_url = base_url

        def query_open_positions(self):
            # TP1 ticket missing from broker => classified as TP_HIT.
            # Leg 2 still open.
            return [
                {
                    "leg_id": second_leg_id,
                    "family_id": family_id,
                    "broker_ticket": second_ticket,
                    "broker_symbol": "XAUUSD",
                    "side": "buy",
                    "lots": "0.01",
                    "open_price": "4662",
                    "sl_price": "4527",
                    "tp_price": "4700",
                    "magic": 123456,
                    "comment": f"tradebot:{family_id}:{second_leg_id}",
                }
            ]

    calls = []

    def fake_modify(*, leg_ids, sl, tp):
        calls.append({"leg_ids": leg_ids, "sl": sl, "tp": tp})

        class Result:
            ok = len(leg_ids)
            failed = 0

        return Result()

    monkeypatch.setattr("app.execution.state_sync.HttpExecutionNode", FakeNode)
    monkeypatch.setattr("app.services.management_live.modify_legs_sl_tp_live", fake_modify)

    result = sync_execution_state(broker="ftmo", platform="mt5")

    assert result.management_actions_applied == 1
    assert len(calls) == 1
    assert calls[0]["leg_ids"] == [second_leg_id]

    row = db_session.execute(
        text(
            """
            SELECT tl1.state AS tp1_state,
                   tl2.sl_price::text AS leg2_sl,
                   tf.meta->'management_applied' AS management_applied
            FROM trade_families tf
            JOIN trade_legs tl1 ON tl1.family_id = tf.family_id AND tl1.leg_index = 1
            JOIN trade_legs tl2 ON tl2.family_id = tf.family_id AND tl2.leg_index = 2
            WHERE tf.family_id = CAST(:family_id AS uuid)
            """
        ),
        {"family_id": family_id},
    ).mappings().first()

    assert row["tp1_state"] == "TP_HIT"
    assert row["leg2_sl"] in {"4662.0000000000", "4662"}
    assert row["management_applied"]["BE_AT_TP1"] is True


def test_sync_live_management_is_idempotent_on_repeat_sync(monkeypatch, db_session):
    family_id, leg_id, broker_ticket = _seed_open_ticket(db_session)

    second_leg_id = str(uuid.uuid4())
    second_ticket = f"IDEMP-{uuid.uuid4().hex[:8]}"

    plan_id = db_session.execute(
        text("SELECT plan_id::text FROM trade_legs WHERE leg_id = CAST(:leg_id AS uuid)"),
        {"leg_id": leg_id},
    ).scalar()

    db_session.execute(
        text(
            """
            UPDATE trade_families
            SET management_rules = '{"BE_AT_TP1": true, "SL_TO_ENTRY_AT_TP1": true}'::jsonb,
                entry_price = 4662
            WHERE family_id = CAST(:family_id AS uuid)
            """
        ),
        {"family_id": family_id},
    )

    db_session.execute(
        text(
            """
            UPDATE execution_tickets
            SET actual_fill_price = 4690,
                sl_price = 4527,
                tp_price = 4690,
                side = 'buy'
            WHERE leg_id = CAST(:leg_id AS uuid)
            """
        ),
        {"leg_id": leg_id},
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
              2, 2, 4662, 4662, 4527, 4700, 0.01, 'OPEN', 0
            )
            """
        ),
        {"leg_id": second_leg_id, "family_id": family_id, "plan_id": plan_id},
    )

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
              'buy', 'market', 4662, 4662,
              4527, 4700, 0.01, 'open', '{}'::jsonb
            )
            """
        ),
        {"leg_id": second_leg_id, "family_id": family_id, "ticket": second_ticket},
    )
    db_session.commit()

    class FakeNode:
        def __init__(self, base_url):
            self.base_url = base_url

        def query_open_positions(self):
            return [
                {
                    "leg_id": second_leg_id,
                    "family_id": family_id,
                    "broker_ticket": second_ticket,
                    "broker_symbol": "XAUUSD",
                    "side": "buy",
                    "lots": "0.01",
                    "open_price": "4662",
                    "sl_price": "4527",
                    "tp_price": "4700",
                    "magic": 123456,
                    "comment": f"tradebot:{family_id}:{second_leg_id}",
                }
            ]

    calls = []

    def fake_modify(*, leg_ids, sl, tp):
        calls.append(leg_ids)

        class Result:
            ok = len(leg_ids)
            failed = 0

        return Result()

    monkeypatch.setattr("app.execution.state_sync.HttpExecutionNode", FakeNode)
    monkeypatch.setattr("app.services.management_live.modify_legs_sl_tp_live", fake_modify)

    first = sync_execution_state(broker="ftmo", platform="mt5")
    second = sync_execution_state(broker="ftmo", platform="mt5")

    assert first.management_actions_applied == 1
    assert second.management_actions_applied == 0
    assert len(calls) == 1
