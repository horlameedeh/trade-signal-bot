import uuid

import pytest
from sqlalchemy import text

from app.db.session import SessionLocal
from app.services.metrics import get_execution_metrics, get_latency_metrics, get_monitoring_snapshot, get_trade_metrics


pytestmark = pytest.mark.integration


@pytest.fixture
def db_session():
    with SessionLocal() as db:
        try:
            yield db
        finally:
            db.rollback()


def _seed_metrics_family(db_session, *, family_state: str = "CLOSED", leg_states: list[str] | None = None) -> str:
    leg_states = leg_states or ["TP_HIT", "SL_HIT"]

    account_id = str(uuid.uuid4())
    intent_id = str(uuid.uuid4())
    plan_id = str(uuid.uuid4())
    family_id = str(uuid.uuid4())
    source_msg_pk = str(uuid.uuid4())
    message_id = 1000000 + (uuid.uuid4().int % 99999)

    db_session.execute(text("INSERT INTO symbols (canonical, asset_class) VALUES ('XAUUSD', 'metal') ON CONFLICT (canonical) DO NOTHING"))

    db_session.execute(
        text(
            """
            INSERT INTO broker_accounts (
              account_id, broker, platform, kind, label,
              allowed_providers, equity_start, equity_current, is_active
            )
            VALUES (
              CAST(:account_id AS uuid), 'ftmo', 'mt5', 'personal_live', 'metrics-seed',
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
            VALUES (CAST(:source_msg_pk AS uuid), -1001239815745, :message_id, 'metrics seed', '{}'::jsonb)
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
              false, false, false, false, 'metrics seed', '{}'::jsonb
            )
            """
        ),
        {
            "intent_id": intent_id,
            "source_msg_pk": source_msg_pk,
            "message_id": message_id,
            "dedupe_hash": f"metrics-{source_msg_pk}",
        },
    )

    db_session.execute(
        text(
            """
            INSERT INTO trade_plans (plan_id, intent_id, account_id, policy_outcome, requires_approval, policy_reasons)
            VALUES (
              CAST(:plan_id AS uuid), CAST(:intent_id AS uuid), CAST(:account_id AS uuid),
              'allow', false, ARRAY['metrics-seed']::text[]
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
              'XAUUSD', 'XAUUSD', 'buy', 100, 90, :tp_count,
              :family_state, false, '{}'::jsonb, '{}'::jsonb
            )
            """
        ),
        {
            "family_id": family_id,
            "intent_id": intent_id,
            "plan_id": plan_id,
            "account_id": account_id,
            "source_msg_pk": source_msg_pk,
            "tp_count": len(leg_states),
            "family_state": family_state,
        },
    )

    for idx, state in enumerate(leg_states, start=1):
        leg_id = str(uuid.uuid4())

        db_session.execute(
            text(
                """
                INSERT INTO trade_legs (
                  leg_id, family_id, plan_id, idx, leg_index, entry_price,
                  requested_entry, sl_price, tp_price, lots, state, placement_delay_ms
                )
                VALUES (
                  CAST(:leg_id AS uuid), CAST(:family_id AS uuid), CAST(:plan_id AS uuid),
                  :idx, :idx, 100, 100, 90, :tp, 0.01, :state, 0
                )
                """
            ),
            {"leg_id": leg_id, "family_id": family_id, "plan_id": plan_id, "idx": idx, "tp": 100 + idx * 10, "state": state},
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
                  'buy', 'market', 100, 100, 90, :tp, 0.01, :status, '{}'::jsonb
                )
                """
            ),
            {
                "leg_id": leg_id,
                "family_id": family_id,
                "ticket": f"METRIC-{uuid.uuid4().hex[:8]}",
                "tp": 100 + idx * 10,
                "status": "closed" if state in {"TP_HIT", "SL_HIT", "CLOSED", "CLOSED_MANUAL"} else "open",
            },
        )

    db_session.execute(
        text(
            """
            INSERT INTO control_actions (action, status, payload)
            VALUES
              ('alert:execution_failure', 'queued', jsonb_build_object('source', 'metrics-test')),
              ('dead_letter:execution', 'queued', jsonb_build_object('source', 'metrics-test')),
              ('execution_retry', 'failed', jsonb_build_object('source', 'metrics-test'))
            """
        )
    )

    db_session.commit()
    return family_id


def test_trade_metrics_include_outcomes(db_session):
    _seed_metrics_family(db_session, family_state="CLOSED", leg_states=["TP_HIT", "SL_HIT", "CLOSED_MANUAL"])

    metrics = get_trade_metrics()

    assert metrics.families_total >= 1
    assert metrics.families_closed >= 1
    assert metrics.legs_tp_hit >= 1
    assert metrics.legs_sl_hit >= 1
    assert metrics.legs_closed_manual >= 1
    assert DecimalLike(metrics.win_rate_pct) >= DecimalLike("0")


def test_execution_metrics_include_errors(db_session):
    _seed_metrics_family(db_session)

    metrics = get_execution_metrics()

    assert metrics.tickets_total >= 2
    assert metrics.execution_errors >= 1
    assert metrics.dead_letters >= 1
    assert metrics.retry_failures >= 1


def test_latency_metrics_available(db_session):
    _seed_metrics_family(db_session)

    metrics = get_latency_metrics()

    assert metrics.avg_seconds_to_ticket is not None
    assert metrics.max_seconds_to_ticket is not None


def test_monitoring_snapshot(db_session):
    _seed_metrics_family(db_session)

    snapshot = get_monitoring_snapshot()

    assert snapshot.trade.families_total >= 1
    assert snapshot.execution.tickets_total >= 1


def DecimalLike(value):
    from decimal import Decimal
    return Decimal(str(value))
