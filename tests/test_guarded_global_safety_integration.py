import uuid
from pathlib import Path

import pytest
from sqlalchemy import text

from app.db.session import SessionLocal
from app.execution.base import OrderLegReceipt, OrderLegRequest
from app.execution.guarded_live_executor import execute_family_with_prop_guard
from app.execution.retry import RetryPolicy


pytestmark = pytest.mark.integration


class FakeAdapter:
    def __init__(self):
        self.calls = 0

    def open_legs(self, legs: list[OrderLegRequest]) -> list[OrderLegReceipt]:
        self.calls += 1
        return [
            OrderLegReceipt(
                leg_id=leg.leg_id,
                broker_ticket=f"GLOBAL-{leg.leg_id[:8]}",
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


def _cleanup_test_data(db) -> None:
    """Delete all rows seeded by integration test fixtures to prevent
    cross-run pollution of global trade counters and exposure queries.
    Uses a pattern match on account label ('%-seed') to catch all test suites."""
    db.execute(
        text(
            """
            DELETE FROM trade_families tf
            USING broker_accounts ba
            WHERE tf.account_id = ba.account_id
              AND ba.label LIKE '%-seed'
            """
        )
    )
    db.execute(
        text(
            """
            DELETE FROM trade_plans tp
            USING broker_accounts ba
            WHERE tp.account_id = ba.account_id
              AND ba.label LIKE '%-seed'
            """
        )
    )
    db.execute(
        text(
            "DELETE FROM trade_intents WHERE dedupe_hash LIKE '%-seed-%'"
            " OR dedupe_hash LIKE 'guard-global-%'"
            " OR dedupe_hash LIKE 'global-safety-%'"
        )
    )
    db.execute(text("DELETE FROM broker_accounts WHERE label LIKE '%-seed'"))
    db.commit()


@pytest.fixture
def db_session():
    with SessionLocal() as db:
        _cleanup_test_data(db)
    with SessionLocal() as db:
        try:
            yield db
        finally:
            db.rollback()
    with SessionLocal() as db:
        _cleanup_test_data(db)


def _seed_family(db_session, *, symbol: str = "XAUUSD", equity_start: str = "10000") -> str:
    account_id = str(uuid.uuid4())
    intent_id = str(uuid.uuid4())
    plan_id = str(uuid.uuid4())
    family_id = str(uuid.uuid4())
    source_msg_pk = str(uuid.uuid4())
    message_id = 1200000 + (uuid.uuid4().int % 99999)

    db_session.execute(
        text(
            """
            INSERT INTO symbols (canonical, asset_class)
            VALUES (:symbol, 'metal')
            ON CONFLICT (canonical) DO NOTHING
            """
        ),
        {"symbol": symbol},
    )

    db_session.execute(
        text(
            """
            INSERT INTO broker_accounts (
              account_id, broker, platform, kind, label,
              allowed_providers, equity_start, equity_current, is_active
            )
            VALUES (
              CAST(:account_id AS uuid), 'ftmo', 'mt5', 'personal_live', 'guard-global-seed',
                            ARRAY[]::provider_code[], :equity_start, :equity_start, false
            )
            """
        ),
        {"account_id": account_id, "equity_start": equity_start},
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
            VALUES (CAST(:source_msg_pk AS uuid), -1001239815745, :message_id, 'guard global seed', '{}'::jsonb)
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
              :message_id, :dedupe_hash, 0.95, :symbol, :symbol, 'buy', 'market',
              100, 90, ARRAY[110,120]::numeric(18,10)[], false, 'normal',
              false, false, false, false, 'guard global seed', '{}'::jsonb
            )
            """
        ),
        {
            "intent_id": intent_id,
            "source_msg_pk": source_msg_pk,
            "message_id": message_id,
            "dedupe_hash": f"guard-global-{source_msg_pk}",
            "symbol": symbol,
        },
    )

    db_session.execute(
        text(
            """
            INSERT INTO trade_plans (plan_id, intent_id, account_id, policy_outcome, requires_approval, policy_reasons)
            VALUES (
              CAST(:plan_id AS uuid), CAST(:intent_id AS uuid), CAST(:account_id AS uuid),
              'allow', false, ARRAY['guard-global-seed']::text[]
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
              :symbol, :symbol, 'buy', 100, 90, 2,
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
            "symbol": symbol,
        },
    )

    for idx in [1, 2]:
        db_session.execute(
            text(
                """
                INSERT INTO trade_legs (
                  leg_id, family_id, plan_id, idx, leg_index, entry_price,
                  requested_entry, sl_price, tp_price, lots, state, placement_delay_ms
                )
                VALUES (
                  gen_random_uuid(), CAST(:family_id AS uuid), CAST(:plan_id AS uuid),
                  :idx, :idx, 100, 100, 90, :tp, 0.01, 'OPEN', 0
                )
                """
            ),
            {"family_id": family_id, "plan_id": plan_id, "idx": idx, "tp": 100 + idx * 10},
        )

    db_session.commit()
    return family_id


def _write_cfg(tmp_path: Path, content: str) -> Path:
    p = tmp_path / "global_safety.yaml"
    p.write_text(content)
    return p


def _count_actions(db_session, family_id: str, action: str) -> int:
    return db_session.execute(
        text(
            """
            SELECT COUNT(*)
            FROM control_actions
            WHERE action = :action
              AND payload->>'family_id' = :family_id
            """
        ),
        {"family_id": family_id, "action": action},
    ).scalar()


def _count_open_trade_families(db_session) -> int:
    return int(
        db_session.execute(
            text(
                """
                SELECT COUNT(*)
                FROM trade_families
                WHERE state IN ('OPEN', 'PARTIALLY_CLOSED', 'PENDING_UPDATE')
                """
            )
        ).scalar()
        or 0
    )


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
              :terminal_name,
              '/tmp/mt5',
              '/tmp/mt5-data',
              20004,
              'running',
              now(),
              now(),
              '{}'::jsonb
            )
            """
        ),
        {"account_id": account_id, "terminal_name": f"global-safety-{family_id[:8]}"},
    )
    db_session.commit()


def test_guarded_executor_blocks_when_global_kill_switch_enabled(monkeypatch, db_session, tmp_path):
    family_id = _seed_family(db_session)
    adapter = FakeAdapter()

    cfg = _write_cfg(
        tmp_path,
        """
enabled: true
kill_switch:
  enabled: true
  reason: emergency_stop
limits: {}
near_limit_threshold_pct: 80
""",
    )

    monkeypatch.setattr("app.risk.global_safety.DEFAULT_GLOBAL_SAFETY_PATH", cfg)

    result = execute_family_with_prop_guard(
        family_id=family_id,
        adapter=adapter,
        retry_policy=RetryPolicy(max_attempts=1, base_delay_seconds=0),
    )

    assert result.allowed is False
    assert result.blocked is True
    assert adapter.calls == 0
    assert "kill_switch_enabled:emergency_stop" in result.risk_reasons
    assert _count_actions(db_session, family_id, "global_safety_block") == 1


def test_guarded_executor_requires_approval_when_global_near_limit(monkeypatch, db_session, tmp_path):
    family_id = _seed_family(db_session)
    adapter = FakeAdapter()
    current_open_trades = _count_open_trade_families(db_session)

    cfg = _write_cfg(
        tmp_path,
        f"""
enabled: true
kill_switch:
  enabled: false
limits:
  max_open_trades: {current_open_trades + 1}
near_limit_threshold_pct: 99
""",
    )

    monkeypatch.setattr("app.risk.global_safety.DEFAULT_GLOBAL_SAFETY_PATH", cfg)

    result = execute_family_with_prop_guard(
        family_id=family_id,
        adapter=adapter,
        retry_policy=RetryPolicy(max_attempts=1, base_delay_seconds=0),
    )

    assert result.allowed is False
    assert result.requires_approval is True
    assert adapter.calls == 0
    assert "near_max_open_trades" in result.risk_reasons
    assert _count_actions(db_session, family_id, "global_safety_requires_approval") == 1


def test_guarded_executor_allows_when_global_safety_allows(monkeypatch, db_session, tmp_path):
    family_id = _seed_family(db_session)
    _seed_terminal_session(db_session, family_id=family_id)
    adapter = FakeAdapter()

    cfg = _write_cfg(
        tmp_path,
        """
enabled: true
kill_switch:
  enabled: false
limits:
  max_open_trades: 999
  max_trades_per_day: 999
  max_exposure_per_symbol:
    XAUUSD: 999999
  global_loss_cutoff: 999999
near_limit_threshold_pct: 80
""",
    )

    monkeypatch.setattr("app.risk.global_safety.DEFAULT_GLOBAL_SAFETY_PATH", cfg)

    result = execute_family_with_prop_guard(
        family_id=family_id,
        adapter=adapter,
        retry_policy=RetryPolicy(max_attempts=1, base_delay_seconds=0),
    )

    assert result.allowed is True
    assert result.execution_result is not None
    assert result.execution_result.sent == 2
    assert adapter.calls == 1
