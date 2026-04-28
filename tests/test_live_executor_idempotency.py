import uuid
from dataclasses import dataclass

import pytest
from sqlalchemy import text

from app.db.session import SessionLocal
from app.execution.base import OrderLegReceipt, OrderLegRequest
from app.execution.live_executor import execute_family_live


pytestmark = pytest.mark.integration


class FakeAdapter:
    def __init__(self):
        self.calls = 0
        self.sent_batches = []

    def open_legs(self, legs: list[OrderLegRequest]) -> list[OrderLegReceipt]:
        self.calls += 1
        self.sent_batches.append(legs)
        return [
            OrderLegReceipt(
                leg_id=leg.leg_id,
                broker_ticket=f"TICKET-{leg.leg_id[:8]}",
                status="open",
                actual_fill_price=leg.requested_entry,
                raw={"ok": True, "leg_id": leg.leg_id},
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


def _seed_family_with_legs(db_session) -> str:
    account_id = str(uuid.uuid4())
    intent_id = str(uuid.uuid4())
    plan_id = str(uuid.uuid4())
    family_id = str(uuid.uuid4())
    source_msg_pk = str(uuid.uuid4())
    source_message_id = 810000 + (uuid.UUID(source_msg_pk).int % 99999)

    db_session.execute(text("INSERT INTO symbols (canonical, asset_class) VALUES ('XAUUSD', 'metal') ON CONFLICT (canonical) DO NOTHING"))

    db_session.execute(
        text(
            """
            INSERT INTO broker_accounts (
              account_id, broker, platform, kind, label,
              allowed_providers, equity_start, is_active
            )
            VALUES (
              CAST(:account_id AS uuid), 'ftmo', 'mt5', 'personal_live', 'seed',
              ARRAY[]::provider_code[], 10000, true
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
            VALUES (CAST(:source_msg_pk AS uuid), -1001239815745, :source_message_id, 'seed', '{}'::jsonb)
            ON CONFLICT DO NOTHING
            """
        ),
        {"source_msg_pk": source_msg_pk, "source_message_id": source_message_id},
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
              :source_message_id, :dedupe_hash, 0.95, 'XAUUSD', 'XAUUSD', 'buy', 'market',
              4662, 4527, ARRAY[4690,4701]::numeric(18,10)[], false, 'normal',
              false, false, false, false, 'seed', '{}'::jsonb
            )
            """
        ),
        {
            "intent_id": intent_id,
            "source_msg_pk": source_msg_pk,
            "source_message_id": source_message_id,
            "dedupe_hash": f"seed-{source_msg_pk}",
        },
    )

    db_session.execute(
        text(
            """
            INSERT INTO trade_plans (plan_id, intent_id, account_id, policy_outcome, requires_approval, policy_reasons)
            VALUES (CAST(:plan_id AS uuid), CAST(:intent_id AS uuid), CAST(:account_id AS uuid), 'allow', false, ARRAY['seed']::text[])
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
              'XAUUSD', 'XAUUSD', 'buy', 4662, 4527, 2, 'OPEN', false, '{}'::jsonb, '{}'::jsonb
            )
            """
        ),
        {"family_id": family_id, "intent_id": intent_id, "plan_id": plan_id, "account_id": account_id, "source_msg_pk": source_msg_pk},
    )

    for idx, tp in enumerate([4690, 4701], start=1):
        db_session.execute(
            text(
                """
                INSERT INTO trade_legs (
                  leg_id, family_id, plan_id, idx, leg_index, entry_price, requested_entry,
                  sl_price, tp_price, lots, state, placement_delay_ms
                )
                VALUES (
                  gen_random_uuid(), CAST(:family_id AS uuid), CAST(:plan_id AS uuid), :idx, :idx,
                  4662, 4662, 4527, :tp, 0.05, 'OPEN', :delay
                )
                """
            ),
            {"family_id": family_id, "plan_id": plan_id, "idx": idx, "tp": tp, "delay": (idx - 1) * 100},
        )

    db_session.commit()
    return family_id


def test_live_executor_persists_tickets(db_session):
    family_id = _seed_family_with_legs(db_session)
    adapter = FakeAdapter()

    result = execute_family_live(family_id=family_id, adapter=adapter)

    assert result.sent == 2
    assert result.tickets_persisted == 2
    assert adapter.calls == 1

    count = db_session.execute(
        text("SELECT COUNT(*) FROM execution_tickets WHERE family_id = CAST(:family_id AS uuid)"),
        {"family_id": family_id},
    ).scalar()
    assert count == 2


def test_live_executor_is_idempotent_on_restart(db_session):
    family_id = _seed_family_with_legs(db_session)
    adapter = FakeAdapter()

    first = execute_family_live(family_id=family_id, adapter=adapter)
    second = execute_family_live(family_id=family_id, adapter=adapter)

    assert first.sent == 2
    assert second.sent == 0
    assert second.skipped_existing == 2
    assert adapter.calls == 1
