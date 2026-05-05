import uuid
from pathlib import Path

import pytest
from sqlalchemy import text

from app.db.session import SessionLocal
from app.execution.base import OrderLegReceipt, OrderLegRequest
from app.execution.guarded_live_executor import execute_family_with_prop_guard
from app.execution.state_sync import sync_execution_state
from app.execution.ticket_ops import close_legs_live, modify_legs_sl_tp_live


pytestmark = pytest.mark.integration


def _write_cfg(tmp_path, content: str) -> Path:
    path = tmp_path / "alert_wiring_global_safety.yaml"
    path.write_text(content, encoding="utf-8")
    return path


class FakeAdapter:
    def open_legs(self, legs: list[OrderLegRequest]) -> list[OrderLegReceipt]:
        return [
            OrderLegReceipt(
                leg_id=leg.leg_id,
                broker_ticket=f"ALERT-{uuid.uuid4().hex[:8]}",
                status="open",
                actual_fill_price=leg.requested_entry,
                raw={"ok": True},
            )
            for leg in legs
        ]

    def modify_sl_tp(self, leg_ids, sl, tp):
        return []

    def close_legs(self, leg_ids):
        return []

    def query_open_positions(self):
        return []


def _cleanup_alert_wiring_data(db) -> None:
    db.execute(text("DELETE FROM control_actions WHERE payload->>'family_id' IN (SELECT family_id::text FROM trade_families WHERE account_id IN (SELECT account_id FROM broker_accounts WHERE label = 'alert-seed'))"))
    db.execute(text("DELETE FROM control_actions WHERE action = 'alert:reconciliation_mismatch' AND payload->>'broker' = 'ftmo' AND payload->>'platform' = 'mt5' AND payload->'data'->>'broker_ticket' = 'BROKER-ONLY'"))
    db.execute(text("DELETE FROM execution_tickets WHERE family_id IN (SELECT family_id FROM trade_families WHERE account_id IN (SELECT account_id FROM broker_accounts WHERE label = 'alert-seed'))"))
    db.execute(text("DELETE FROM terminal_sessions WHERE broker_account_id IN (SELECT account_id FROM broker_accounts WHERE label = 'alert-seed') OR terminal_name LIKE 'alert-%'"))
    db.execute(text("DELETE FROM trade_legs WHERE family_id IN (SELECT family_id FROM trade_families WHERE account_id IN (SELECT account_id FROM broker_accounts WHERE label = 'alert-seed'))"))
    db.execute(text("DELETE FROM trade_families WHERE account_id IN (SELECT account_id FROM broker_accounts WHERE label = 'alert-seed')"))
    db.execute(text("DELETE FROM trade_plans WHERE account_id IN (SELECT account_id FROM broker_accounts WHERE label = 'alert-seed')"))
    db.execute(text("DELETE FROM trade_intents WHERE dedupe_hash LIKE 'alert-%'"))
    db.execute(text("DELETE FROM broker_accounts WHERE label = 'alert-seed'"))
    db.execute(text("DELETE FROM users WHERE display_name LIKE 'alert-user-%'"))
    db.execute(text("DELETE FROM execution_nodes WHERE name = 'alert-test-node' AND broker = 'ftmo' AND platform = 'mt5'"))
    db.commit()


@pytest.fixture
def db_session():
    with SessionLocal() as db:
        _cleanup_alert_wiring_data(db)
    with SessionLocal() as db:
        try:
            yield db
        finally:
            db.rollback()
    with SessionLocal() as db:
        _cleanup_alert_wiring_data(db)


@pytest.fixture(autouse=True)
def _isolated_global_safety(tmp_path, monkeypatch):
    cfg = _write_cfg(
        tmp_path,
        """
enabled: true
kill_switch:
  enabled: false
limits:
  max_trades_per_day: 999999
  max_open_trades: 999999
  max_exposure_per_symbol:
    XAUUSD: 999999
  global_loss_cutoff: 999999
near_limit_threshold_pct: 99
""",
    )
    monkeypatch.setattr("app.risk.global_safety.DEFAULT_GLOBAL_SAFETY_PATH", cfg)


def _latest_alert(db_session, category: str | None = None):
    where = "WHERE action LIKE 'alert:%'"
    params = {}
    if category:
        where += " AND action = :action"
        params["action"] = f"alert:{category}"

    return db_session.execute(
        text(
            f"""
            SELECT action, payload
            FROM control_actions
            {where}
            ORDER BY created_at DESC
            LIMIT 1
            """
        ),
        params,
    ).mappings().first()


def _seed_family(db_session) -> tuple[str, list[str]]:
    account_id = str(uuid.uuid4())
    user_id = str(uuid.uuid4())
    intent_id = str(uuid.uuid4())
    plan_id = str(uuid.uuid4())
    family_id = str(uuid.uuid4())
    source_msg_pk = str(uuid.uuid4())
    message_id = 1_700_000_000 + (uuid.UUID(source_msg_pk).int % 100_000_000)

    db_session.execute(text("INSERT INTO symbols (canonical, asset_class) VALUES ('XAUUSD', 'metal') ON CONFLICT (canonical) DO NOTHING"))

    db_session.execute(
        text(
            """
            INSERT INTO users (user_id, telegram_user_id, display_name, role, is_active)
            VALUES (CAST(:user_id AS uuid), :telegram_user_id, :display_name, 'user', true)
            """
        ),
        {
            "user_id": user_id,
            "telegram_user_id": 1_800_000_000 + (uuid.UUID(user_id).int % 100_000_000),
            "display_name": f"alert-user-{account_id}",
        },
    )

    db_session.execute(
        text(
            """
            INSERT INTO broker_accounts (
              account_id, user_id, broker, platform, kind, label,
              allowed_providers, equity_start, equity_current, is_active
            )
            VALUES (
              CAST(:account_id AS uuid), CAST(:user_id AS uuid), 'ftmo', 'mt5', 'personal_live', 'alert-seed',
                            ARRAY[]::provider_code[], 10000, 10000, false
            )
            """
        ),
        {"account_id": account_id, "user_id": user_id},
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
            VALUES (CAST(:source_msg_pk AS uuid), -1001239815745, :message_id, 'alert seed', '{}'::jsonb)
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
              false, false, false, false, 'alert seed', '{}'::jsonb
            )
            """
        ),
        {"intent_id": intent_id, "source_msg_pk": source_msg_pk, "message_id": message_id, "dedupe_hash": f"alert-{source_msg_pk}"},
    )

    db_session.execute(
        text(
            """
            INSERT INTO trade_plans (plan_id, intent_id, account_id, policy_outcome, requires_approval, policy_reasons)
            VALUES (
              CAST(:plan_id AS uuid), CAST(:intent_id AS uuid), CAST(:account_id AS uuid),
              'allow', false, ARRAY['alert-seed']::text[]
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
              'OPEN', false, '{"BE_AT_TP1": true}'::jsonb, '{}'::jsonb
            )
            """
        ),
        {"family_id": family_id, "intent_id": intent_id, "plan_id": plan_id, "account_id": account_id, "source_msg_pk": source_msg_pk},
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

    db_session.execute(
        text(
            """
            INSERT INTO execution_nodes (name, broker, platform, base_url, is_active, meta)
            VALUES ('alert-test-node', 'ftmo', 'mt5', 'http://fake-node', true, '{}'::jsonb)
            ON CONFLICT (broker, platform, name)
            DO UPDATE SET base_url=EXCLUDED.base_url, is_active=true
            """
        )
    )

    db_session.commit()
    return family_id, leg_ids


def _seed_terminal_session(db_session, *, family_id: str) -> None:
    account_id = db_session.execute(
        text(
            """
            SELECT account_id::text
            FROM trade_families
            WHERE family_id = CAST(:family_id AS uuid)
            LIMIT 1
            """
        ),
        {"family_id": family_id},
    ).scalar()

    db_session.execute(
        text(
            """
            INSERT INTO terminal_sessions (
              session_id,
              broker_account_id,
              user_id,
              terminal_name,
              terminal_path,
              data_dir,
              port,
              status,
              started_at,
              last_heartbeat,
              meta
            )
            VALUES (
              gen_random_uuid(),
              CAST(:account_id AS uuid),
              (SELECT user_id FROM broker_accounts WHERE account_id = CAST(:account_id AS uuid)),
              :terminal_name,
              '/tmp/mt5',
              '/tmp/mt5-data',
              20003,
              'running',
              now(),
              now(),
              '{}'::jsonb
            )
            """
        ),
        {"account_id": account_id, "terminal_name": f"alert-{family_id[:8]}"},
    )
    db_session.commit()


def test_guarded_execution_queues_trade_opened_alert(db_session):
    family_id, leg_ids = _seed_family(db_session)
    _seed_terminal_session(db_session, family_id=family_id)

    result = execute_family_with_prop_guard(family_id=family_id, adapter=FakeAdapter())

    assert result.allowed is True
    alert = _latest_alert(db_session, "trade_opened")
    assert alert is not None
    assert alert["payload"]["family_id"] == family_id


def test_ticket_ops_queue_modify_and_close_alerts(monkeypatch, db_session):
    family_id, leg_ids = _seed_family(db_session)
    _seed_terminal_session(db_session, family_id=family_id)

    # Execute first to create tickets.
    execute_family_with_prop_guard(family_id=family_id, adapter=FakeAdapter())

    class FakeNode:
        def __init__(self, base_url):
            self.base_url = base_url

        def modify_ticket_sl_tp(self, payload):
            return [{"leg_id": p["leg_id"], "ok": True, "status": "modified"} for p in payload]

        def close_tickets(self, payload):
            return [{"leg_id": p["leg_id"], "ok": True, "status": "closed"} for p in payload]

    monkeypatch.setattr("app.execution.ticket_ops.HttpExecutionNode", FakeNode)

    mod = modify_legs_sl_tp_live(leg_ids=[leg_ids[0]], sl="100", tp=None)
    assert mod.ok == 1
    alert = _latest_alert(db_session, "sl_tp_modified")
    assert alert is not None
    assert alert["payload"]["family_id"] == family_id

    close = close_legs_live(leg_ids=[leg_ids[0]])
    assert close.ok == 1
    alert = _latest_alert(db_session, "trade_closed")
    assert alert is not None
    assert alert["payload"]["family_id"] == family_id


def test_state_sync_queues_reconciliation_mismatch_alert(monkeypatch, db_session):
    family_id, leg_ids = _seed_family(db_session)

    class FakeNode:
        def __init__(self, base_url):
            self.base_url = base_url

        def query_open_positions(self):
            return [
                {
                    "broker_ticket": "BROKER-ONLY",
                    "broker_symbol": "XAUUSD",
                    "side": "buy",
                    "lots": "0.01",
                    "comment": "manual",
                }
            ]

    monkeypatch.setattr("app.execution.state_sync.HttpExecutionNode", FakeNode)

    sync_execution_state(broker="ftmo", platform="mt5")

    alert = _latest_alert(db_session, "reconciliation_mismatch")
    assert alert is not None
    assert alert["payload"]["category"] == "reconciliation_mismatch"
