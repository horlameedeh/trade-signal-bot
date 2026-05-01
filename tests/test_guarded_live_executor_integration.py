import uuid

import pytest
from sqlalchemy import text

from app.db.session import SessionLocal
from app.execution.base import OrderLegReceipt, OrderLegRequest
from app.execution.guarded_live_executor import execute_family_with_prop_guard


pytestmark = pytest.mark.integration


class FakeAdapter:
    def __init__(self):
        self.calls = 0

    def open_legs(self, legs: list[OrderLegRequest]) -> list[OrderLegReceipt]:
        self.calls += 1
        return [
            OrderLegReceipt(
                leg_id=leg.leg_id,
                broker_ticket=f"TICKET-{leg.leg_id[:8]}",
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


def _seed_family(
    db_session,
    *,
    equity_start: str = "10000",
    entry: str = "100",
    sl: str = "90",
    lots: str = "1.00",
    broker: str = "ftmo",
) -> str:
    account_id = str(uuid.uuid4())
    intent_id = str(uuid.uuid4())
    plan_id = str(uuid.uuid4())
    family_id = str(uuid.uuid4())
    source_msg_pk = str(uuid.uuid4())
    message_id = 890000 + (uuid.uuid4().int % 99999)

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
              CAST(:account_id AS uuid), :broker, 'mt5', 'personal_live', 'guard-seed',
              ARRAY[]::provider_code[], :equity_start, :equity_start, true
            )
            """
        ),
        {"account_id": account_id, "broker": broker, "equity_start": equity_start},
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
            VALUES (CAST(:source_msg_pk AS uuid), -1001239815745, :message_id, 'guard seed', '{}'::jsonb)
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
              :entry, :sl, ARRAY[110]::numeric(18,10)[], false, 'normal',
              false, false, false, false, 'guard seed', '{}'::jsonb
            )
            """
        ),
        {
            "intent_id": intent_id,
            "source_msg_pk": source_msg_pk,
            "message_id": message_id,
            "dedupe_hash": f"guard-{source_msg_pk}",
            "entry": entry,
            "sl": sl,
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
              ARRAY['guard-seed']::text[]
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
              'XAUUSD', 'XAUUSD', 'buy', :entry, :sl, 1, 'OPEN', false, '{}'::jsonb, '{}'::jsonb
            )
            """
        ),
        {
            "family_id": family_id,
            "intent_id": intent_id,
            "plan_id": plan_id,
            "account_id": account_id,
            "source_msg_pk": source_msg_pk,
            "entry": entry,
            "sl": sl,
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
              gen_random_uuid(), CAST(:family_id AS uuid), CAST(:plan_id AS uuid),
              1, 1, :entry, :entry, :sl, 110, :lots, 'OPEN', 0
            )
            """
        ),
        {"family_id": family_id, "plan_id": plan_id, "entry": entry, "sl": sl, "lots": lots},
    )

    db_session.commit()
    return family_id


def test_guard_allows_safe_trade_and_executes(db_session):
    family_id = _seed_family(db_session, equity_start="10000", entry="100", sl="90", lots="1.00")
    adapter = FakeAdapter()

    result = execute_family_with_prop_guard(family_id=family_id, adapter=adapter)

    assert result.allowed is True
    assert result.blocked is False
    assert result.execution_result is not None
    assert result.execution_result.sent == 1
    assert adapter.calls == 1


def test_guard_blocks_breaching_trade_and_does_not_execute(db_session):
    family_id = _seed_family(db_session, equity_start="100", entry="100", sl="90", lots="1.00")
    adapter = FakeAdapter()

    result = execute_family_with_prop_guard(family_id=family_id, adapter=adapter)

    assert result.allowed is False
    assert result.blocked is True
    assert result.execution_result is None
    assert adapter.calls == 0

    action = db_session.execute(
        text(
            """
            SELECT action
            FROM control_actions
            WHERE payload->>'family_id' = :family_id
            ORDER BY created_at DESC
            LIMIT 1
            """
        ),
        {"family_id": family_id},
    ).scalar()

    assert action == "risk_block"


def test_guard_requires_approval_near_limit_and_does_not_execute(db_session):
    family_id = _seed_family(db_session, equity_start="10000", entry="100", sl="90", lots="1.00")
    adapter = FakeAdapter()

    result = execute_family_with_prop_guard(
        family_id=family_id,
        adapter=adapter,
        daily_realized_pnl="-390",
        total_realized_pnl="-390",
    )

    assert result.allowed is False
    assert result.requires_approval is True
    assert result.execution_result is None
    assert adapter.calls == 0

    action = db_session.execute(
        text(
            """
            SELECT action
            FROM control_actions
            WHERE payload->>'family_id' = :family_id
            ORDER BY created_at DESC
            LIMIT 1
            """
        ),
        {"family_id": family_id},
    ).scalar()

    assert action == "risk_requires_approval"
