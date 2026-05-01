import uuid

import pytest
from sqlalchemy import text

from app.db.session import SessionLocal
from app.execution.base import OrderLegReceipt, OrderLegRequest
from app.execution.retry import RetryPolicy, execute_family_live_with_retry


pytestmark = pytest.mark.integration


class FlakyAdapter:
    def __init__(self, fail_times: int):
        self.fail_times = fail_times
        self.calls = 0

    def open_legs(self, legs: list[OrderLegRequest]) -> list[OrderLegReceipt]:
        self.calls += 1
        if self.calls <= self.fail_times:
            raise RuntimeError("temporary network error")

        return [
            OrderLegReceipt(
                leg_id=leg.leg_id,
                broker_ticket=f"RETRY-{leg.leg_id[:8]}",
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


@pytest.fixture
def db_session():
    with SessionLocal() as db:
        try:
            yield db
        finally:
            db.rollback()


def _seed_family(db_session) -> str:
    account_id = str(uuid.uuid4())
    intent_id = str(uuid.uuid4())
    plan_id = str(uuid.uuid4())
    family_id = str(uuid.uuid4())
    source_msg_pk = str(uuid.uuid4())
    message_id = 970000 + (uuid.uuid4().int % 99999)

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
              CAST(:account_id AS uuid), 'ftmo', 'mt5', 'personal_live', 'retry-seed',
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
            VALUES (CAST(:source_msg_pk AS uuid), -1001239815745, :message_id, 'retry seed', '{}'::jsonb)
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
              false, false, false, false, 'retry seed', '{}'::jsonb
            )
            """
        ),
        {
            "intent_id": intent_id,
            "source_msg_pk": source_msg_pk,
            "message_id": message_id,
            "dedupe_hash": f"retry-{source_msg_pk}",
        },
    )

    db_session.execute(
        text(
            """
            INSERT INTO trade_plans (plan_id, intent_id, account_id, policy_outcome, requires_approval, policy_reasons)
            VALUES (
              CAST(:plan_id AS uuid), CAST(:intent_id AS uuid), CAST(:account_id AS uuid),
              'allow', false, ARRAY['retry-seed']::text[]
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


def _count_tickets(db_session, family_id: str) -> int:
    return db_session.execute(
        text("SELECT COUNT(*) FROM execution_tickets WHERE family_id = CAST(:family_id AS uuid)"),
        {"family_id": family_id},
    ).scalar()


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


def test_retry_recovers_after_transient_failure_without_duplicates(db_session):
    family_id = _seed_family(db_session)
    adapter = FlakyAdapter(fail_times=1)

    result = execute_family_live_with_retry(
        family_id=family_id,
        adapter=adapter,
        policy=RetryPolicy(max_attempts=3, base_delay_seconds=0),
        sleep_fn=lambda _: None,
    )

    assert result.success is True
    assert result.attempts == 2
    assert adapter.calls == 2
    assert result.execution_result is not None
    assert result.execution_result.sent == 2
    assert _count_tickets(db_session, family_id) == 2
    assert _count_actions(db_session, family_id, "execution_retry") == 2


def test_retry_dead_letters_after_repeated_failures(db_session):
    family_id = _seed_family(db_session)
    adapter = FlakyAdapter(fail_times=99)

    result = execute_family_live_with_retry(
        family_id=family_id,
        adapter=adapter,
        policy=RetryPolicy(max_attempts=2, base_delay_seconds=0),
        sleep_fn=lambda _: None,
    )

    assert result.success is False
    assert result.dead_lettered is True
    assert result.attempts == 2
    assert _count_tickets(db_session, family_id) == 0
    assert _count_actions(db_session, family_id, "dead_letter:execution") == 1
    assert _count_actions(db_session, family_id, "alert:execution_failure") == 1


def test_retry_is_idempotent_if_second_run_retries_same_family(db_session):
    family_id = _seed_family(db_session)

    first = execute_family_live_with_retry(
        family_id=family_id,
        adapter=FlakyAdapter(fail_times=0),
        policy=RetryPolicy(max_attempts=1, base_delay_seconds=0),
        sleep_fn=lambda _: None,
    )

    second = execute_family_live_with_retry(
        family_id=family_id,
        adapter=FlakyAdapter(fail_times=0),
        policy=RetryPolicy(max_attempts=1, base_delay_seconds=0),
        sleep_fn=lambda _: None,
    )

    assert first.success is True
    assert second.success is True
    assert first.execution_result is not None
    assert second.execution_result is not None
    assert first.execution_result.sent == 2
    assert second.execution_result.sent == 0
    assert second.execution_result.skipped_existing == 2
    assert _count_tickets(db_session, family_id) == 2
