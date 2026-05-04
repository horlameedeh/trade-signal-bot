import uuid
from pathlib import Path

import pytest
from sqlalchemy import text

from app.db.session import SessionLocal
from app.risk import global_safety
from app.risk.global_safety import evaluate_global_safety


def _write_cfg(tmp_path, content: str) -> Path:
    p = tmp_path / "global_safety.yaml"
    p.write_text(content, encoding="utf-8")
    return p


def _cleanup_cap_test_data(db) -> None:
    db.execute(
        text(
            """
            DELETE FROM trade_legs tl
            USING trade_families tf, broker_accounts ba
            WHERE tl.family_id = tf.family_id
              AND tf.account_id = ba.account_id
              AND ba.label LIKE 'cap-test-%'
            """
        )
    )
    db.execute(
        text(
            """
            DELETE FROM trade_families tf
            USING broker_accounts ba
            WHERE tf.account_id = ba.account_id
              AND ba.label LIKE 'cap-test-%'
            """
        )
    )
    db.execute(
        text(
            """
            DELETE FROM trade_plans tp
            USING broker_accounts ba
            WHERE tp.account_id = ba.account_id
              AND ba.label LIKE 'cap-test-%'
            """
        )
    )
    db.execute(text("DELETE FROM trade_intents WHERE dedupe_hash LIKE 'cap-test-%'"))
    db.execute(text("DELETE FROM broker_accounts WHERE label LIKE 'cap-test-%'"))
    db.commit()


@pytest.fixture
def db_session():
    with SessionLocal() as db:
        _cleanup_cap_test_data(db)
    with SessionLocal() as db:
        try:
            yield db
        finally:
            db.rollback()
    with SessionLocal() as db:
        _cleanup_cap_test_data(db)


def _seed_cap_test_family(db_session, *, label: str, lots: list[str]) -> str:
    account_id = str(uuid.uuid4())
    intent_id = str(uuid.uuid4())
    plan_id = str(uuid.uuid4())
    family_id = str(uuid.uuid4())
    source_msg_pk = str(uuid.uuid4())
    message_id = 1300000 + (uuid.uuid4().int % 99999)
    dedupe_hash = f"cap-test-{source_msg_pk}"

    db_session.execute(
        text(
            """
            INSERT INTO broker_accounts (
              account_id, broker, platform, kind, label,
              base_currency, equity_start, equity_current,
              allowed_providers, is_active
            )
            VALUES (
              CAST(:account_id AS uuid), 'vantage', 'mt5', 'personal_live', :label,
              'GBP', 500, 500,
              ARRAY[]::provider_code[], true
            )
            """
        ),
        {"account_id": account_id, "label": label},
    )

    db_session.execute(
        text(
            """
            INSERT INTO telegram_chats (chat_id, provider_code)
            VALUES (-1001239815745, 'fredtrading')
            ON CONFLICT (chat_id) DO UPDATE SET provider_code = 'fredtrading'
            """
        )
    )

    db_session.execute(
        text(
            """
            INSERT INTO telegram_messages (msg_pk, chat_id, message_id, text, raw_json)
            VALUES (
              CAST(:source_msg_pk AS uuid), -1001239815745, :message_id,
              'cap test seed', '{}'::jsonb
            )
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
              false, false, false, false, 'cap test', '{}'::jsonb
            )
            """
        ),
        {
            "intent_id": intent_id,
            "source_msg_pk": source_msg_pk,
            "message_id": message_id,
            "dedupe_hash": dedupe_hash,
        },
    )

    db_session.execute(
        text(
            """
            INSERT INTO trade_plans (
              plan_id, intent_id, account_id, policy_outcome, requires_approval, policy_reasons
            )
            VALUES (
              CAST(:plan_id AS uuid), CAST(:intent_id AS uuid), CAST(:account_id AS uuid),
              'allow', false, ARRAY['cap-test']::text[]
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
              symbol_canonical, side, entry_price, sl_price, tp_count,
              state, is_stub, management_rules, meta
            )
            VALUES (
              CAST(:family_id AS uuid), CAST(:intent_id AS uuid), CAST(:plan_id AS uuid),
              'fredtrading', CAST(:account_id AS uuid), -1001239815745, CAST(:source_msg_pk AS uuid),
              'XAUUSD', 'buy', 100, 90, 1,
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

    for idx, lot in enumerate(lots, start=1):
        db_session.execute(
            text(
                """
                INSERT INTO trade_legs (
                  leg_id, family_id, plan_id, idx, leg_index, entry_price,
                  sl_price, tp_price, lots, state
                )
                VALUES (
                  gen_random_uuid(), CAST(:family_id AS uuid), CAST(:plan_id AS uuid),
                  :idx, :idx, 100, 90, 110, :lots, 'OPEN'
                )
                """
            ),
            {"family_id": family_id, "plan_id": plan_id, "idx": idx, "lots": lot},
        )

    db_session.commit()
    return family_id


def test_kill_switch_blocks(tmp_path):
    cfg = _write_cfg(
        tmp_path,
        """
enabled: true
kill_switch:
  enabled: true
  reason: manual_stop
limits: {}
near_limit_threshold_pct: 80
""",
    )

    result = evaluate_global_safety(symbol="XAUUSD", path=cfg)

    assert result.decision == "block"
    assert "kill_switch_enabled:manual_stop" in result.reasons


def test_disabled_global_safety_allows(tmp_path):
    cfg = _write_cfg(
        tmp_path,
        """
enabled: false
kill_switch:
  enabled: true
  reason: ignored
limits: {}
near_limit_threshold_pct: 80
""",
    )

    result = evaluate_global_safety(symbol="XAUUSD", path=cfg)

    assert result.decision == "allow"
    assert result.reasons == ["global_safety_disabled"]


def test_empty_limits_allow(tmp_path):
    cfg = _write_cfg(
        tmp_path,
        """
enabled: true
kill_switch:
  enabled: false
limits: {}
near_limit_threshold_pct: 80
""",
    )

    result = evaluate_global_safety(symbol="XAUUSD", path=cfg)

    assert result.decision == "allow"


def test_execution_caps_block_when_family_total_lots_exceed_limit(monkeypatch, tmp_path):
        cfg = _write_cfg(
                tmp_path,
                """
enabled: true
kill_switch:
    enabled: false
limits: {}
execution_caps:
    default_max_total_lots: 2.00

    brokers:
        vantage:
            max_total_lots: 0.04

    accounts:
        "vantage:personal_live:500":
            max_total_lots: 0.04
near_limit_threshold_pct: 80
""",
        )

        monkeypatch.setattr(global_safety, "_count_trades_today", lambda: 0)
        monkeypatch.setattr(global_safety, "_count_open_trades", lambda: 0)
        monkeypatch.setattr(global_safety, "_symbol_open_exposure", lambda _symbol: global_safety.Decimal("0"))
        monkeypatch.setattr(global_safety, "_global_realized_loss", lambda: global_safety.Decimal("0"))
        monkeypatch.setattr(
                global_safety,
                "_family_execution_cap_context",
                lambda *, family_id: {
                        "broker": "vantage",
                        "account_type": "personal_live",
                        "account_size": "500",
                        "total_lots": "0.05",
                },
        )

        result = evaluate_global_safety(family_id="family-1", symbol="XAUUSD", path=cfg)

        assert result.decision == "block"
        assert result.reasons == ["max_total_lots_exceeded:vantage:0.05>0.04"]


@pytest.mark.integration
def test_global_safety_blocks_when_family_total_lots_exceeds_broker_cap(db_session, tmp_path):
        cfg = _write_cfg(
                tmp_path,
                """
enabled: true

kill_switch:
    enabled: false
    reason: ""

limits:
    max_trades_per_day: 999
    max_open_trades: 999

execution_caps:
    brokers:
        vantage:
            max_total_lots: 0.04
""",
        )

        family_id = _seed_cap_test_family(
                db_session,
                label="cap-test-vantage",
                lots=["0.03", "0.02"],
        )

        result = evaluate_global_safety(family_id=family_id, path=cfg)

        assert result.decision == "block"
        assert any("max_total_lots_exceeded:vantage" in reason for reason in result.reasons)


@pytest.mark.integration
def test_global_safety_allows_when_family_total_lots_equals_cap(db_session, tmp_path):
        cfg = _write_cfg(
                tmp_path,
                """
enabled: true

kill_switch:
    enabled: false
    reason: ""

limits:
    max_trades_per_day: 999
    max_open_trades: 999

execution_caps:
    brokers:
        vantage:
            max_total_lots: 0.04
""",
        )

        family_id = _seed_cap_test_family(
                db_session,
                label="cap-test-vantage-ok",
                lots=["0.01", "0.01", "0.01", "0.01"],
        )

        result = evaluate_global_safety(family_id=family_id, path=cfg)

        assert result.decision == "allow"
