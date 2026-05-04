from __future__ import annotations

from dataclasses import dataclass

import pytest

from app.execution.guarded_live_executor import execute_family_with_prop_guard
from app.execution.terminal_sessions import TerminalSessionRoutingError


@dataclass(frozen=True)
class _FakeGlobalSafetyResult:
    decision: str = "allow"
    reasons: list[str] = None
    trades_today: int = 0
    open_trades: int = 0
    symbol: str | None = None
    symbol_exposure: str = "0"
    global_realized_loss: str = "0"

    def __post_init__(self):
        if self.reasons is None:
            object.__setattr__(self, "reasons", [])


@dataclass(frozen=True)
class _FakePropRiskResult:
    decision: str = "allow"
    reasons: list[str] = None
    daily_loss_limit: str = "0"
    total_loss_limit: str = "0"
    current_daily_loss: str = "0"
    current_total_loss: str = "0"
    new_trade_risk: str = "0"
    current_open_risk: str = "0"

    def __post_init__(self):
        if self.reasons is None:
            object.__setattr__(self, "reasons", [])


@dataclass(frozen=True)
class _FakeExecutionResult:
    sent: int = 0
    tickets_persisted: int = 0
    skipped_existing: int = 0


@dataclass(frozen=True)
class _FakeRetryResult:
    success: bool
    attempts: int
    execution_result: _FakeExecutionResult | None


class _UnusedAdapter:
    pass


def test_execute_family_with_prop_guard_checks_terminal_session_before_retry(monkeypatch):
    call_order: list[str] = []

    monkeypatch.setattr(
        "app.execution.guarded_live_executor.evaluate_global_safety",
        lambda *, family_id: _FakeGlobalSafetyResult(),
    )
    monkeypatch.setattr(
        "app.execution.guarded_live_executor.evaluate_family_prop_risk",
        lambda **kwargs: _FakePropRiskResult(),
    )
    monkeypatch.setattr(
        "app.execution.guarded_live_executor._family_alert_context",
        lambda *, family_id: {},
    )
    monkeypatch.setattr(
        "app.execution.guarded_live_executor.alert_trade_opened",
        lambda **kwargs: None,
    )

    def fake_assert_terminal_session_routing(*, family_id: str) -> None:
        call_order.append(f"routing:{family_id}")

    def fake_execute_family_live_with_retry(*, family_id: str, adapter, policy):
        call_order.append(f"retry:{family_id}")
        return _FakeRetryResult(
            success=True,
            attempts=1,
            execution_result=_FakeExecutionResult(sent=1, tickets_persisted=1, skipped_existing=0),
        )

    monkeypatch.setattr(
        "app.execution.guarded_live_executor._assert_terminal_session_routing",
        fake_assert_terminal_session_routing,
    )
    monkeypatch.setattr(
        "app.execution.guarded_live_executor.execute_family_live_with_retry",
        fake_execute_family_live_with_retry,
    )

    result = execute_family_with_prop_guard(family_id="family-1", adapter=_UnusedAdapter())

    assert result.allowed is True
    assert call_order == ["routing:family-1", "retry:family-1"]


def test_execute_family_with_prop_guard_raises_and_records_terminal_routing_block(monkeypatch):
    recorded: list[tuple[str, str, str]] = []

    monkeypatch.setattr(
        "app.execution.guarded_live_executor.evaluate_global_safety",
        lambda *, family_id: _FakeGlobalSafetyResult(),
    )
    monkeypatch.setattr(
        "app.execution.guarded_live_executor.evaluate_family_prop_risk",
        lambda **kwargs: _FakePropRiskResult(),
    )
    monkeypatch.setattr(
        "app.execution.guarded_live_executor._family_account_id",
        lambda *, family_id: "account-1",
    )

    def fake_resolve_terminal_session_for_account(*, broker_account_id: str):
        raise TerminalSessionRoutingError(
            f"missing_terminal_session:broker_account_id={broker_account_id}"
        )

    def fake_write_terminal_routing_block(*, family_id: str, account_id: str, reason: str) -> None:
        recorded.append((family_id, account_id, reason))

    def fail_if_retry_called(*, family_id: str, adapter, policy):
        raise AssertionError("retry should not run when terminal routing fails")

    monkeypatch.setattr(
        "app.execution.guarded_live_executor.resolve_terminal_session_for_account",
        fake_resolve_terminal_session_for_account,
    )
    monkeypatch.setattr(
        "app.execution.guarded_live_executor._write_terminal_routing_block",
        fake_write_terminal_routing_block,
    )
    monkeypatch.setattr(
        "app.execution.guarded_live_executor.execute_family_live_with_retry",
        fail_if_retry_called,
    )

    with pytest.raises(TerminalSessionRoutingError, match="missing_terminal_session"):
        execute_family_with_prop_guard(family_id="family-2", adapter=_UnusedAdapter())

    assert recorded == [
        (
            "family-2",
            "account-1",
            "missing_terminal_session:broker_account_id=account-1",
        )
    ]