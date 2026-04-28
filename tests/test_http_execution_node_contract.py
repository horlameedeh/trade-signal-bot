from unittest.mock import Mock

import requests

from app.execution.base import OrderLegRequest
from app.execution.http_node import HttpExecutionNode


class FakeResponse:
    def __init__(self, payload):
        self.payload = payload

    def raise_for_status(self):
        return None

    def json(self):
        return self.payload


def test_http_node_open_legs_parses_receipts(monkeypatch):
    def fake_post(url, json, timeout):
        assert url == "http://node/open-legs"
        assert len(json["legs"]) == 1
        return FakeResponse(
            {
                "receipts": [
                    {
                        "leg_id": "leg-1",
                        "broker_ticket": "12345",
                        "status": "open",
                        "actual_fill_price": "4662",
                    }
                ]
            }
        )

    monkeypatch.setattr(requests, "post", fake_post)

    node = HttpExecutionNode("http://node")
    receipts = node.open_legs(
        [
            OrderLegRequest(
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
        ]
    )

    assert len(receipts) == 1
    assert receipts[0].broker_ticket == "12345"


def test_http_node_modify_close_and_query(monkeypatch):
    calls = []

    def fake_post(url, json, timeout):
        calls.append((url, json))
        if url.endswith("/modify-sl-tp"):
            return FakeResponse({"results": [{"leg_id": "leg-1", "ok": True, "status": "modified"}]})
        if url.endswith("/close-legs"):
            return FakeResponse({"results": [{"leg_id": "leg-1", "ok": True, "status": "closed"}]})
        raise AssertionError(url)

    def fake_get(url, timeout):
        assert url == "http://node/open-positions"
        return FakeResponse({"positions": [{"leg_id": "leg-1", "broker_ticket": "12345"}]})

    monkeypatch.setattr(requests, "post", fake_post)
    monkeypatch.setattr(requests, "get", fake_get)

    node = HttpExecutionNode("http://node")

    mod = node.modify_sl_tp(["leg-1"], sl="4662", tp="4701")
    close = node.close_legs(["leg-1"])
    pos = node.query_open_positions()

    assert mod[0]["status"] == "modified"
    assert close[0]["status"] == "closed"
    assert pos[0]["broker_ticket"] == "12345"
