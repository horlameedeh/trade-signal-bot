from __future__ import annotations

import uuid
from dataclasses import dataclass

import pytest
from sqlalchemy import text

from app.db.session import SessionLocal
from app.execution.base import ExecutionAdapter, OrderLegReceipt, OrderLegRequest
from app.execution.guarded_live_executor import execute_family_with_prop_guard
from app.execution.terminal_sessions import TerminalSessionRoutingError


pytestmark = pytest.mark.integration


@dataclass
class CountingAdapter(ExecutionAdapter):
    calls: int = 0

    def open_legs(self, legs: list[OrderLegRequest]) -> list[OrderLegReceipt]:
        self.calls += 1
        return []

    def modify_sl_tp(self, leg_ids, sl, tp):
        return []

    def close_legs(self, leg_ids):
        return []

    def query_open_positions(self):
        return []


@dataclass(frozen=True)
class _AllowDecision:
    decision: str = "allow"
    reasons: list[str] = None

    def __post_init__(self):
        if self.reasons is None:
            object.__setattr__(self, "reasons", [])


def _cleanup(db, *, broker: str = "vantage") -> None:
    db.execute(
        text("DELETE FROM control_actions WHERE payload->>'source' = 'terminal_session_guard'")
    )
    db.execute(
        text("DELETE FROM terminal_sessions WHERE terminal_name LIKE 'guard-terminal-%'")
    )
    db.execute(
        text(
            """
            DELETE FROM trade_legs
            WHERE family_id IN (
              SELECT family_id
              FROM trade_families
              WHERE broker_symbol = 'XAUUSD.guard'
            )
            """
        )
    )
    db.execute(
        text(
            "DELETE FROM trade_families WHERE broker_symbol = 'XAUUSD.guard'"
        )
    )
    db.execute(
        text(
            """
            DELETE FROM trade_plans
            WHERE policy_reasons = ARRAY['guard-terminal-seed']::text[]
            """
        )
    )
    db.execute(
        text(
            "DELETE FROM trade_intents WHERE dedupe_hash LIKE 'guard-terminal-%'"
        )
    )
    db.execute(
        text(
            "DELETE FROM telegram_messages WHERE text = 'guard terminal seed'"
        )
    )
    db.execute(
        text("DELETE FROM broker_accounts WHERE label LIKE 'guard-terminal-%'")
    )
    db.execute(
        text("DELETE FROM users WHERE display_name LIKE 'guard-terminal-user-%'")
    )
    db.commit()


@pytest.fixture
def db_session():
    with SessionLocal() as db:
        _cleanup(db)
    with SessionLocal() as db:
        try:
            yield db
        finally:
            db.rollback()
    with SessionLocal() as db:
        _cleanup(db)


def _allow_pre_execution_guards(monkeypatch) -> None:
    monkeypatch.setattr(
        "app.execution.guarded_live_executor.evaluate_global_safety",
        lambda *, family_id: _AllowDecision(),
    )
    monkeypatch.setattr(
        "app.execution.guarded_live_executor.evaluate_family_prop_risk",
        lambda **kwargs: _AllowDecision(),
    )


def _seed_family(db, *, broker: str = "vantage") -> tuple[str, str]:
    account_id = str(uuid.uuid4())
    user_id = str(uuid.uuid4())
    family_id = str(uuid.uuid4())
    intent_id = str(uuid.uuid4())
    plan_id = str(uuid.uuid4())
    source_msg_pk = str(uuid.uuid4())
    message_id = 1_700_000_000 + (uuid.UUID(source_msg_pk).int % 100_000_000)
    telegram_user_id = 980000 + (uuid.uuid4().int % 99999)

    db.execute(
        text(
            """
            INSERT INTO symbols (canonical, asset_class)
            VALUES ('XAUUSD', 'metal')
            ON CONFLICT (canonical) DO NOTHING
            """
        )
    )

    db.execute(
        text(
            """
            INSERT INTO users (user_id, telegram_user_id, display_name, role, is_active)
            VALUES (
              CAST(:user_id AS uuid), :telegram_user_id, :display_name, 'user', true
            )
            """
        ),
        {
            "user_id": user_id,
            "telegram_user_id": telegram_user_id,
            "display_name": f"guard-terminal-user-{account_id}",
        },
    )

    db.execute(
        text(
            """
            INSERT INTO broker_accounts (
              account_id, user_id, broker, platform, kind, label,
              base_currency, equity_start, equity_current,
              allowed_providers, is_active
            )
            VALUES (
              CAST(:account_id AS uuid), CAST(:user_id AS uuid), :broker, 'mt5', 'personal_live', :label,
              'GBP', 500, 500,
              ARRAY[]::provider_code[], false
            )
            """
        ),
        {
            "account_id": account_id,
            "user_id": user_id,
            "broker": broker,
            "label": f"guard-terminal-{account_id}",
        },
    )

    db.execute(
        text(
            """
            INSERT INTO telegram_chats (chat_id, provider_code)
            VALUES (-1001239815745, 'fredtrading')
            ON CONFLICT (chat_id) DO UPDATE SET provider_code='fredtrading'
            """
        )
    )

    db.execute(
        text(
            """
            INSERT INTO telegram_messages (msg_pk, chat_id, message_id, text, raw_json)
            VALUES (CAST(:source_msg_pk AS uuid), -1001239815745, :message_id, 'guard terminal seed', '{}'::jsonb)
            """
        ),
        {"source_msg_pk": source_msg_pk, "message_id": message_id},
    )

    db.execute(
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
              false, false, false, false, 'guard terminal seed', '{}'::jsonb
            )
            """
        ),
        {
            "intent_id": intent_id,
            "source_msg_pk": source_msg_pk,
            "message_id": message_id,
            "dedupe_hash": f"guard-terminal-{source_msg_pk}",
        },
    )

    db.execute(
        text(
            """
            INSERT INTO trade_plans (
              plan_id, intent_id, account_id, policy_outcome, requires_approval, policy_reasons
            )
            VALUES (
              CAST(:plan_id AS uuid), CAST(:intent_id AS uuid), CAST(:account_id AS uuid),
              'allow', false, ARRAY['guard-terminal-seed']::text[]
            )
            """
        ),
        {"plan_id": plan_id, "intent_id": intent_id, "account_id": account_id},
    )

    db.execute(
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
              'XAUUSD', 'XAUUSD.guard', 'buy', 100, 90, 1,
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

    db.commit()
    return family_id, account_id


def _seed_terminal(db, *, account_id: str, status: str = "running", suffix: str = "a") -> None:
    db.execute(
        text(
            """
            INSERT INTO terminal_sessions (
                            broker_account_id, user_id, terminal_name, terminal_path,
              data_dir, port, status, last_heartbeat, meta
            )
            VALUES (
                            CAST(:account_id AS uuid),
                            (SELECT user_id FROM broker_accounts WHERE account_id = CAST(:account_id AS uuid)),
                            :name, '/tmp/terminal.exe',
              '/tmp/data', 9101, :status, now(), '{}'::jsonb
            )
            """
        ),
        {"account_id": account_id, "name": f"guard-terminal-{suffix}", "status": status},
    )
    db.commit()


def _seed_family_with_terminal_account(db, *, broker: str = "vantage") -> tuple[str, str]:
        family_id, account_id = _seed_family(db, broker=broker)
        _seed_terminal(db, account_id=account_id, suffix="owned")
        return family_id, account_id


def _count_terminal_blocks(db, family_id: str) -> int:
    return int(
        db.execute(
            text(
                """
                SELECT COUNT(*)
                FROM control_actions
                WHERE action = 'terminal_routing_block'
                  AND payload->>'family_id' = :family_id
                """
            ),
            {"family_id": family_id},
        ).scalar()
        or 0
    )


def test_guarded_execution_blocks_when_terminal_session_missing(monkeypatch, db_session):
    _allow_pre_execution_guards(monkeypatch)
    family_id, _account_id = _seed_family(db_session)
    adapter = CountingAdapter()

    with pytest.raises(TerminalSessionRoutingError, match="missing_terminal_session"):
        execute_family_with_prop_guard(family_id=family_id, adapter=adapter)

    assert adapter.calls == 0
    assert _count_terminal_blocks(db_session, family_id) == 1


def test_guarded_execution_blocks_when_terminal_session_ambiguous(monkeypatch, db_session):
    _allow_pre_execution_guards(monkeypatch)
    family_id, account_id = _seed_family(db_session)
    _seed_terminal(db_session, account_id=account_id, suffix="a")

    def _raise_ambiguous(*, broker_account_id: str):
        raise TerminalSessionRoutingError(
            f"ambiguous_terminal_session:broker_account_id={broker_account_id}:count=2"
        )

    monkeypatch.setattr(
        "app.execution.guarded_live_executor.resolve_terminal_session_for_account",
        _raise_ambiguous,
    )

    adapter = CountingAdapter()

    with pytest.raises(TerminalSessionRoutingError, match="ambiguous_terminal_session"):
        execute_family_with_prop_guard(family_id=family_id, adapter=adapter)

    assert adapter.calls == 0
    assert _count_terminal_blocks(db_session, family_id) == 1


def test_guarded_execution_blocks_when_terminal_session_stale(monkeypatch, db_session):
    _allow_pre_execution_guards(monkeypatch)
    family_id, account_id = _seed_family(db_session)

    db_session.execute(
        text(
            """
            INSERT INTO terminal_sessions (
                            broker_account_id, user_id, terminal_name, terminal_path,
              data_dir, port, status, last_heartbeat, meta
            )
            VALUES (
                            CAST(:account_id AS uuid),
                            (SELECT user_id FROM broker_accounts WHERE account_id = CAST(:account_id AS uuid)),
                            'guard-terminal-stale', '/tmp/terminal.exe',
              '/tmp/data', 9102, 'running', now() - interval '10 minutes', '{}'::jsonb
            )
            """
        ),
        {"account_id": account_id},
    )
    db_session.commit()

    adapter = CountingAdapter()

    with pytest.raises(TerminalSessionRoutingError, match="stale_terminal_session"):
        execute_family_with_prop_guard(family_id=family_id, adapter=adapter)

    assert adapter.calls == 0
    assert _count_terminal_blocks(db_session, family_id) == 1


def test_guarded_execution_logs_missing_account_owner_block(db_session, monkeypatch):
    _allow_pre_execution_guards(monkeypatch)
    family_id, account_id = _seed_family_with_terminal_account(db_session, broker="ftmo")
    adapter = CountingAdapter()

    db_session.execute(
        text("UPDATE broker_accounts SET user_id = NULL WHERE account_id = CAST(:account_id AS uuid)"),
        {"account_id": account_id},
    )
    db_session.commit()

    with pytest.raises(TerminalSessionRoutingError, match="missing_account_owner"):
        execute_family_with_prop_guard(
            family_id=family_id,
            adapter=adapter,
        )

    row = db_session.execute(
        text(
            """
            SELECT payload->>'reason'
            FROM control_actions
            WHERE action = 'terminal_routing_block'
              AND payload->>'family_id' = :family_id
            ORDER BY created_at DESC
            LIMIT 1
            """
        ),
        {"family_id": family_id},
    ).scalar()

    assert adapter.calls == 0
    assert row is not None
    assert "missing_account_owner" in row
