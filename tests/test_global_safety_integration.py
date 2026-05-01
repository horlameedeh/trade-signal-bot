import uuid
from pathlib import Path

import pytest
from sqlalchemy import text

from app.db.session import SessionLocal
from app.risk.global_safety import evaluate_global_safety


pytestmark = pytest.mark.integration


def _cleanup_global_safety_data(db) -> None:
    """Delete all rows seeded by integration test fixtures to prevent cross-run pollution.
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
            " OR dedupe_hash LIKE 'global-safety-%'"
        )
    )
    db.execute(text("DELETE FROM broker_accounts WHERE label LIKE '%-seed'"))
    db.commit()


@pytest.fixture
def db_session():
    with SessionLocal() as db:
        _cleanup_global_safety_data(db)
    with SessionLocal() as db:
        try:
            yield db
        finally:
            db.rollback()
    with SessionLocal() as db:
        _cleanup_global_safety_data(db)


def _write_cfg(tmp_path, content: str) -> Path:
    p = tmp_path / "global_safety.yaml"
    p.write_text(content)
    return p


def _seed_family(
    db_session,
    *,
    symbol: str = "XAUUSD",
    family_state: str = "OPEN",
    leg_state: str = "OPEN",
    entry: str = "100",
    sl: str = "90",
    lots: str = "1.00",
    realized_pnl: str | None = None,
) -> str:
    account_id = str(uuid.uuid4())
    intent_id = str(uuid.uuid4())
    plan_id = str(uuid.uuid4())
    family_id = str(uuid.uuid4())
    source_msg_pk = str(uuid.uuid4())
    message_id = 1100000 + (uuid.uuid4().int % 99999)

    asset_class = "metal" if symbol == "XAUUSD" else "index"

    db_session.execute(
        text(
            """
            INSERT INTO symbols (canonical, asset_class)
            VALUES (:symbol, :asset_class)
            ON CONFLICT (canonical) DO NOTHING
            """
        ),
        {"symbol": symbol, "asset_class": asset_class},
    )

    db_session.execute(
        text(
            """
            INSERT INTO broker_accounts (
              account_id, broker, platform, kind, label,
              allowed_providers, equity_start, equity_current, is_active
            )
            VALUES (
              CAST(:account_id AS uuid), 'ftmo', 'mt5', 'personal_live', 'global-safety-seed',
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
            VALUES (CAST(:source_msg_pk AS uuid), -1001239815745, :message_id, 'global safety seed', '{}'::jsonb)
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
              :entry, :sl, ARRAY[110]::numeric(18,10)[], false, 'normal',
              false, false, false, false, 'global safety seed', '{}'::jsonb
            )
            """
        ),
        {
            "intent_id": intent_id,
            "source_msg_pk": source_msg_pk,
            "message_id": message_id,
            "dedupe_hash": f"global-safety-{source_msg_pk}",
            "symbol": symbol,
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
              'allow', false, ARRAY['global-safety-seed']::text[]
            )
            """
        ),
        {"plan_id": plan_id, "intent_id": intent_id, "account_id": account_id},
    )

    meta_expr = "'{}'::jsonb"
    params = {
        "family_id": family_id,
        "intent_id": intent_id,
        "plan_id": plan_id,
        "account_id": account_id,
        "source_msg_pk": source_msg_pk,
        "symbol": symbol,
        "entry": entry,
        "sl": sl,
        "family_state": family_state,
    }

    if realized_pnl is not None:
        meta_expr = "jsonb_build_object('lifecycle', jsonb_build_object('realized_pnl', CAST(:realized_pnl AS text)))"
        params["realized_pnl"] = realized_pnl

    db_session.execute(
        text(
            f"""
            INSERT INTO trade_families (
              family_id, intent_id, plan_id, provider, account_id, chat_id, source_msg_pk,
              symbol_canonical, broker_symbol, side, entry_price, sl_price, tp_count,
              state, is_stub, management_rules, meta
            )
            VALUES (
              CAST(:family_id AS uuid), CAST(:intent_id AS uuid), CAST(:plan_id AS uuid),
              'fredtrading', CAST(:account_id AS uuid), -1001239815745, CAST(:source_msg_pk AS uuid),
              :symbol, :symbol, 'buy', :entry, :sl, 1,
              :family_state, false, '{{}}'::jsonb, {meta_expr}
            )
            """
        ),
        params,
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
              1, 1, :entry, :entry, :sl, 110, :lots, :leg_state, 0
            )
            """
        ),
        {
            "family_id": family_id,
            "plan_id": plan_id,
            "entry": entry,
            "sl": sl,
            "lots": lots,
            "leg_state": leg_state,
        },
    )

    db_session.commit()
    return family_id


def test_max_trades_per_day_blocks(db_session, tmp_path):
    cfg = _write_cfg(
        tmp_path,
        """
enabled: true
kill_switch:
  enabled: false
limits:
  max_trades_per_day: 1
near_limit_threshold_pct: 80
""",
    )

    _seed_family(db_session)

    result = evaluate_global_safety(symbol="XAUUSD", path=cfg)

    assert result.decision == "block"
    assert "max_trades_per_day_breached" in result.reasons


def test_max_open_trades_blocks(db_session, tmp_path):
    cfg = _write_cfg(
        tmp_path,
        """
enabled: true
kill_switch:
  enabled: false
limits:
  max_open_trades: 1
near_limit_threshold_pct: 80
""",
    )

    _seed_family(db_session, family_state="OPEN")

    result = evaluate_global_safety(symbol="XAUUSD", path=cfg)

    assert result.decision == "block"
    assert "max_open_trades_breached" in result.reasons


def test_max_exposure_per_symbol_blocks(db_session, tmp_path):
    cfg = _write_cfg(
        tmp_path,
        """
enabled: true
kill_switch:
  enabled: false
limits:
  max_exposure_per_symbol:
    XAUUSD: 10
near_limit_threshold_pct: 80
""",
    )

    _seed_family(db_session, symbol="XAUUSD", entry="100", sl="90", lots="1.00")

    result = evaluate_global_safety(symbol="XAUUSD", path=cfg)

    assert result.decision == "block"
    assert "max_exposure_per_symbol_breached" in result.reasons


def test_near_symbol_exposure_requires_approval(db_session, tmp_path):
    cfg = _write_cfg(
        tmp_path,
        """
enabled: true
kill_switch:
  enabled: false
limits:
  max_exposure_per_symbol:
    XAUUSD: 100
near_limit_threshold_pct: 80
""",
    )

    _seed_family(db_session, symbol="XAUUSD", entry="100", sl="90", lots="8.00")

    result = evaluate_global_safety(symbol="XAUUSD", path=cfg)

    assert result.decision == "require_approval"
    assert "near_max_exposure_per_symbol" in result.reasons


def test_global_loss_cutoff_blocks(db_session, tmp_path):
    cfg = _write_cfg(
        tmp_path,
        """
enabled: true
kill_switch:
  enabled: false
limits:
  global_loss_cutoff: 100
near_limit_threshold_pct: 80
""",
    )

    _seed_family(
        db_session,
        family_state="CLOSED",
        leg_state="SL_HIT",
        realized_pnl="-100",
    )

    result = evaluate_global_safety(symbol="XAUUSD", path=cfg)

    assert result.decision == "block"
    assert "global_loss_cutoff_breached" in result.reasons


def test_global_loss_near_limit_requires_approval(db_session, tmp_path):
    cfg = _write_cfg(
        tmp_path,
        """
enabled: true
kill_switch:
  enabled: false
limits:
  global_loss_cutoff: 100
near_limit_threshold_pct: 80
""",
    )

    _seed_family(
        db_session,
        family_state="CLOSED",
        leg_state="SL_HIT",
        realized_pnl="-80",
    )

    result = evaluate_global_safety(symbol="XAUUSD", path=cfg)

    assert result.decision == "require_approval"
    assert "near_global_loss_cutoff" in result.reasons
