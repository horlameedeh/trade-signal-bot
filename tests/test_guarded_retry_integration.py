import uuid

import pytest
from sqlalchemy import text

from app.db.session import SessionLocal
from app.execution.base import OrderLegReceipt, OrderLegRequest
from app.execution.guarded_live_executor import execute_family_with_prop_guard
from app.execution.retry import RetryPolicy


pytestmark = pytest.mark.integration


class FlakyAdapter:
    def __init__(self, fail_times: int):
        self.fail_times = fail_times
        self.calls = 0

    def open_legs(self, legs: list[OrderLegRequest]) -> list[OrderLegReceipt]:
        self.calls += 1
        if self.calls <= self.fail_times:
            raise RuntimeError("temporary failure")

        return [
            OrderLegReceipt(
                leg_id=leg.leg_id,
                broker_ticket=f"GUARD-{leg.leg_id[:8]}",
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


def _seed_family(db_session, *, equity_start: str = "10000", lots: float = 0.01) -> str:
    account_id = str(uuid.uuid4())
    intent_id = str(uuid.uuid4())
    plan_id = str(uuid.uuid4())
    family_id = str(uuid.uuid4())
    source_msg_pk = str(uuid.uuid4())
    message_id = 980000 + (uuid.uuid4().int % 99999)

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
              CAST(:account_id AS uuid), 'ftmo', 'mt5', 'personal_live', 'guard-retry-seed',
              ARRAY[]::provider_code[], :equity_start, :equity_start, true
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
            VALUES (CAST(:source_msg_pk AS uuid), -1001239815745, :message_id, 'guard retry seed', '{}'::jsonb)
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
              false, false, false, false, 'guard retry seed', '{}'::jsonb
            )
            """
        ),
        {
            "intent_id": intent_id,
            "source_msg_pk": source_msg_pk,
            "message_id": message_id,
            "dedupe_hash": f"guard-retry-{source_msg_pk}",
        },
    )

    db_session.execute(
        text(
            """
            INSERT INTO trade_plans (plan_id, intent_id, account_id, policy_outcome, requires_approval, policy_reasons)
            VALUES (
              CAST(:plan_id AS uuid), CAST(:intent_id AS uuid), CAST(:account_id AS uuid),
              'allow', false, ARRAY['guard-retry-seed']::text[]
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
                  :idx, :idx, 100, 100, 90, :tp, :lots, 'OPEN', 0
                )
                """
            ),
            {"family_id": family_id, "plan_id": plan_id, "idx": idx, "tp": 100 + idx * 10, "lots": lots},
        )

    db_session.commit()
    return family_id


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


def _count_tickets(db_session, family_id: str) -> int:
    return db_session.execute(
        text("SELECT COUNT(*) FROM execution_tickets WHERE family_id = CAST(:family_id AS uuid)"),
        {"family_id": family_id},
    ).scalar()


def test_guarded_executor_retries_and_succeeds(db_session):
    family_id = _seed_family(db_session)
    adapter = FlakyAdapter(fail_times=1)

    result = execute_family_with_prop_guard(
        family_id=family_id,
        adapter=adapter,
        retry_policy=RetryPolicy(max_attempts=3, base_delay_seconds=0),
    )

    assert result.allowed is True
    assert result.execution_result is not None
    assert result.execution_result.sent == 2
    assert adapter.calls == 2
    assert _count_tickets(db_session, family_id) == 2
    assert _count_actions(db_session, family_id, "execution_retry") == 2
    assert _count_actions(db_session, family_id, "alert:trade_opened") == 1


def test_guarded_executor_dead_letters_after_retry_failure(db_session):
    family_id = _seed_family(db_session)
    adapter = FlakyAdapter(fail_times=99)

    result = execute_family_with_prop_guard(
        family_id=family_id,
        adapter=adapter,
        retry_policy=RetryPolicy(max_attempts=2, base_delay_seconds=0),
    )

    assert result.allowed is False
    assert result.blocked is True
    assert result.execution_result is None
    assert adapter.calls == 2
    assert _count_tickets(db_session, family_id) == 0
    assert _count_actions(db_session, family_id, "dead_letter:execution") == 1
    assert _count_actions(db_session, family_id, "alert:execution_failure") == 1


def test_guarded_executor_still_blocks_prop_risk_before_retry(db_session):
    # lots=1.0 → risk per leg = abs(100-90)*1 = 10, total=20 > daily_limit=5 (5% of 100) → block
    family_id = _seed_family(db_session, equity_start="100", lots=1.0)
    adapter = FlakyAdapter(fail_times=0)

    result = execute_family_with_prop_guard(
        family_id=family_id,
        adapter=adapter,
        retry_policy=RetryPolicy(max_attempts=3, base_delay_seconds=0),
    )

    assert result.allowed is False
    assert result.blocked is True
    assert adapter.calls == 0
    assert _count_actions(db_session, family_id, "risk_block") == 1
