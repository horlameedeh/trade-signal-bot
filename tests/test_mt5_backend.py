from types import SimpleNamespace

import pytest

from app.execution.mt5_backend import Mt5Backend, Mt5Config
from app.execution.node_contract import OpenLegRequestModel


class FakeMt5:
    ORDER_TYPE_BUY = 0
    ORDER_TYPE_SELL = 1
    ORDER_TYPE_BUY_LIMIT = 2
    ORDER_TYPE_SELL_LIMIT = 3
    ORDER_TYPE_BUY_STOP = 4
    ORDER_TYPE_SELL_STOP = 5
    TRADE_ACTION_DEAL = 1
    TRADE_ACTION_PENDING = 5
    TRADE_ACTION_SLTP = 6
    ORDER_TIME_GTC = 0
    ORDER_FILLING_IOC = 1
    TRADE_RETCODE_DONE = 10009
    TRADE_RETCODE_PLACED = 10008

    def __init__(self):
        self.requests = []

    def initialize(self, path=None):
        return True

    def shutdown(self):
        return None

    def terminal_info(self):
        return SimpleNamespace(trade_allowed=True)

    def account_info(self):
        return SimpleNamespace(login=123, server="demo")

    def symbol_info(self, symbol):
        return SimpleNamespace(visible=True)

    def symbol_info_tick(self, symbol):
        return SimpleNamespace(ask=4662.5, bid=4662.0)

    def order_send(self, request):
        self.requests.append(request)
        return SimpleNamespace(retcode=10009, order=123456, deal=654321, price=request["price"])

    def positions_get(self):
        return []

    def last_error(self):
        return (0, "ok")


def test_mt5_backend_blocks_when_live_disabled():
    backend = Mt5Backend(FakeMt5(), Mt5Config(terminal_path=None, live_enabled=False))

    leg = OpenLegRequestModel(
        leg_id="leg-1",
        family_id="fam-1",
        broker="vantage",
        platform="mt5",
        broker_symbol="GOLD",
        side="buy",
        order_type="market",
        lots="0.02",
        requested_entry="4662",
        sl_price="4527",
        tp_price="4690",
        magic=123456,
        comment="tradebot:fam-1:leg-1",
    )

    with pytest.raises(RuntimeError, match="live trading is disabled"):
        backend.open_leg(leg)


def test_mt5_backend_market_order_builds_request():
    fake = FakeMt5()
    backend = Mt5Backend(fake, Mt5Config(terminal_path=None, live_enabled=True))

    leg = OpenLegRequestModel(
        leg_id="leg-1",
        family_id="fam-1",
        broker="vantage",
        platform="mt5",
        broker_symbol="GOLD",
        side="buy",
        order_type="market",
        lots="0.02",
        requested_entry="4662",
        sl_price="4527",
        tp_price="4690",
        magic=123456,
        comment="tradebot:fam-1:leg-1",
    )

    receipt = backend.open_leg(leg)

    assert receipt.leg_id == "leg-1"
    assert receipt.broker_ticket == "123456"
    assert fake.requests[0]["symbol"] == "GOLD"
    assert fake.requests[0]["volume"] == 0.02
    assert fake.requests[0]["tp"] == 4690.0


def test_mt5_backend_limit_order_uses_requested_entry():
    fake = FakeMt5()
    backend = Mt5Backend(fake, Mt5Config(terminal_path=None, live_enabled=True))

    leg = OpenLegRequestModel(
        leg_id="leg-2",
        family_id="fam-1",
        broker="vantage",
        platform="mt5",
        broker_symbol="GOLD",
        side="buy",
        order_type="limit",
        lots="0.02",
        requested_entry="4661",
        sl_price="4527",
        tp_price="4701",
        magic=123456,
        comment="tradebot:fam-1:leg-2",
    )

    backend.open_leg(leg)

    assert fake.requests[0]["action"] == fake.TRADE_ACTION_PENDING
    assert fake.requests[0]["price"] == 4661.0
