from contextlib import contextmanager

import pytest

from app.services import account_routing_guard
from app.services.account_routing_guard import (
    AccountRoutingError,
    get_unique_active_account,
)


class _FakeResult:
    def __init__(self, rows):
        self._rows = rows

    def mappings(self):
        return self

    def all(self):
        return self._rows


class _FakeSession:
    def __init__(self, rows):
        self._rows = rows

    def execute(self, *_args, **_kwargs):
        return _FakeResult(self._rows)


def _patch_session_local(monkeypatch: pytest.MonkeyPatch, rows):
    @contextmanager
    def _session_local():
        yield _FakeSession(rows)

    monkeypatch.setattr(account_routing_guard, "SessionLocal", _session_local)


def test_get_unique_active_account_returns_single_active_account(monkeypatch):
    _patch_session_local(
        monkeypatch,
        [
            {
                "account_id": "00000000-0000-0000-0000-000000000001",
                "broker": "vantage",
                "platform": "mt5",
                "label": "unit-vantage-routing",
            }
        ],
    )

    route = get_unique_active_account(broker="vantage", platform="mt5")

    assert route.broker == "vantage"
    assert route.platform == "mt5"
    assert route.label == "unit-vantage-routing"


def test_get_unique_active_account_fails_when_missing(monkeypatch):
    _patch_session_local(monkeypatch, [])

    with pytest.raises(AccountRoutingError, match="No active broker account"):
        get_unique_active_account(broker="bullwaves", platform="mt4")
