import uuid

import pytest
from sqlalchemy import text

from app.db.session import SessionLocal
from app.services.management_live import apply_live_be_at_tp1


pytestmark = pytest.mark.integration


@pytest.fixture
def db_session():
    with SessionLocal() as db:
        try:
            yield db
        finally:
            db.rollback()


def _seed_family_with_tickets(db_session, *, tp1_state: str = "TP_HIT") -> tuple[str, list[str]]:
    ticket_prefix = uuid.uuid4().hex[:8].upper()
    account_id = str(uuid.uuid4())
    intent_id = str(uuid.uuid4())
    plan_id = str(uuid.uuid4())
    family_id = str(uuid.uuid4())
    source_msg_pk = str(uuid.uuid4())
    message_id = 950000 + (uuid.uuid4().int % 99999)

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
              CAST(:account_id AS uuid), 'ftmo', 'mt5', 'personal_live', 'mgmt-seed',
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
            VALUES (CAST(:source_msg_pk AS uuid), -1001239815745, :message_id, 'mgmt seed', '{}'::jsonb)
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
              100, 90, ARRAY[110,120,130]::numeric(18,10)[], false, 'normal',
              false, false, false, false, 'mgmt seed', '{}'::jsonb
            )
            """
        ),
        {
            "intent_id": intent_id,
            "source_msg_pk": source_msg_pk,
            "message_id": message_id,
            "dedupe_hash": f"mgmt-{source_msg_pk}",
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
              ARRAY['mgmt-seed']::text[]
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
              'XAUUSD', 'XAUUSD', 'buy', 100, 90, 3,
              'PARTIALLY_CLOSED', false,
              '{"BE_AT_TP1": true, "SL_TO_ENTRY_AT_TP1": true}'::jsonb,
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

    leg_ids: list[str] = []

    for idx, state in [(1, tp1_state), (2, "OPEN"), (3, "OPEN")]:
        leg_id = str(uuid.uuid4())
        leg_ids.append(leg_id)
        tp = 100 + (idx * 10)

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
            {"leg_id": leg_id, "family_id": family_id, "plan_id": plan_id, "idx": idx, "tp": tp, "state": state},
        )

        if state == "OPEN":
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
                      'buy', 'market', 100, 100,
                      90, :tp, 0.01, 'open', '{}'::jsonb
                    )
                    """
                ),
                {"leg_id": leg_id, "family_id": family_id, "ticket": f"{ticket_prefix}-{idx}", "tp": tp},
            )

    db_session.commit()
    return family_id, leg_ids


def test_be_at_tp1_modifies_remaining_open_legs(monkeypatch, db_session):
    family_id, leg_ids = _seed_family_with_tickets(db_session)

    calls = []

    def fake_modify(*, leg_ids, sl, tp):
        calls.append({"leg_ids": leg_ids, "sl": sl, "tp": tp})

        class Result:
            ok = len(leg_ids)
            failed = 0

        return Result()

    monkeypatch.setattr("app.services.management_live.modify_legs_sl_tp_live", fake_modify)

    result = apply_live_be_at_tp1(family_id=family_id)

    assert result.triggered is True
    assert result.legs_modified == 2
    assert calls[0]["sl"] == "100.0000000000" or calls[0]["sl"] == "100"
    assert set(calls[0]["leg_ids"]) == set(leg_ids[1:])

    rows = db_session.execute(
        text(
            """
            SELECT leg_index, sl_price::text
            FROM trade_legs
            WHERE family_id = CAST(:family_id AS uuid)
            ORDER BY leg_index
            """
        ),
        {"family_id": family_id},
    ).mappings().all()

    assert rows[1]["sl_price"] in {"100.0000000000", "100"}
    assert rows[2]["sl_price"] in {"100.0000000000", "100"}


def test_be_at_tp1_is_idempotent(monkeypatch, db_session):
    family_id, leg_ids = _seed_family_with_tickets(db_session)

    calls = []

    def fake_modify(*, leg_ids, sl, tp):
        calls.append(leg_ids)

        class Result:
            ok = len(leg_ids)
            failed = 0

        return Result()

    monkeypatch.setattr("app.services.management_live.modify_legs_sl_tp_live", fake_modify)

    first = apply_live_be_at_tp1(family_id=family_id)
    second = apply_live_be_at_tp1(family_id=family_id)

    assert first.legs_modified == 2
    assert second.legs_modified == 0
    assert second.reason == "already_applied"
    assert len(calls) == 1


def test_be_at_tp1_does_not_trigger_before_tp1_hit(monkeypatch, db_session):
    family_id, leg_ids = _seed_family_with_tickets(db_session, tp1_state="OPEN")

    def fail_modify(*args, **kwargs):
        raise AssertionError("modify should not be called")

    monkeypatch.setattr("app.services.management_live.modify_legs_sl_tp_live", fail_modify)

    result = apply_live_be_at_tp1(family_id=family_id)

    assert result.triggered is False
    assert result.reason == "tp1_not_hit"


def test_be_at_tp1_skips_when_rule_not_enabled(monkeypatch, db_session):
    family_id, leg_ids = _seed_family_with_tickets(db_session)

    db_session.execute(
        text(
            """
            UPDATE trade_families
            SET management_rules = '{}'::jsonb
            WHERE family_id = CAST(:family_id AS uuid)
            """
        ),
        {"family_id": family_id},
    )
    db_session.commit()

    result = apply_live_be_at_tp1(family_id=family_id)

    assert result.triggered is False
    assert result.reason == "rule_not_enabled"
