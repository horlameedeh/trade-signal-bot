from fastapi.testclient import TestClient

from app.execution.node_stub import app


def test_health_contract():
    client = TestClient(app)
    r = client.get("/health")
    assert r.status_code == 200

    data = r.json()
    assert data["ok"] is True
    assert data["platform"] == "stub"
    assert data["terminal_connected"] is False
    assert data["trading_enabled"] is False


def test_open_legs_contract_creates_stub_positions():
    client = TestClient(app)

    payload = {
        "legs": [
            {
                "leg_id": "leg-1",
                "family_id": "fam-1",
                "broker": "vantage",
                "platform": "mt5",
                "broker_symbol": "GOLD",
                "side": "buy",
                "order_type": "market",
                "lots": "0.02",
                "requested_entry": "4662",
                "sl_price": "4527",
                "tp_price": "4690",
                "magic": 123456,
                "comment": "tradebot:fam-1:leg-1",
            },
            {
                "leg_id": "leg-2",
                "family_id": "fam-1",
                "broker": "vantage",
                "platform": "mt5",
                "broker_symbol": "GOLD",
                "side": "buy",
                "order_type": "market",
                "lots": "0.02",
                "requested_entry": "4662",
                "sl_price": "4527",
                "tp_price": "4701",
                "magic": 123456,
                "comment": "tradebot:fam-1:leg-2",
            },
        ]
    }

    r = client.post("/open-legs", json=payload)
    assert r.status_code == 200

    data = r.json()
    assert len(data["receipts"]) == 2
    assert data["receipts"][0]["leg_id"] == "leg-1"
    assert data["receipts"][0]["broker_ticket"].startswith("STUB-")

    positions = client.get("/open-positions").json()["positions"]
    assert len(positions) >= 2
    assert any(p["leg_id"] == "leg-1" for p in positions)


def test_modify_sl_tp_contract():
    client = TestClient(app)

    client.post(
        "/open-legs",
        json={
            "legs": [
                {
                    "leg_id": "leg-mod",
                    "family_id": "fam-mod",
                    "broker": "vantage",
                    "platform": "mt5",
                    "broker_symbol": "GOLD",
                    "side": "buy",
                    "order_type": "market",
                    "lots": "0.02",
                    "requested_entry": "4662",
                    "sl_price": "4527",
                    "tp_price": "4690",
                    "magic": 123456,
                    "comment": "tradebot:fam-mod:leg-mod",
                }
            ]
        },
    )

    r = client.post("/modify-sl-tp", json={"leg_ids": ["leg-mod"], "sl": "4662", "tp": "4701"})
    assert r.status_code == 200

    data = r.json()
    assert data["results"][0]["ok"] is True
    assert data["results"][0]["status"] == "modified"

    positions = client.get("/open-positions").json()["positions"]
    pos = [p for p in positions if p["leg_id"] == "leg-mod"][0]
    assert pos["sl_price"] == "4662"
    assert pos["tp_price"] == "4701"


def test_close_legs_contract():
    client = TestClient(app)

    client.post(
        "/open-legs",
        json={
            "legs": [
                {
                    "leg_id": "leg-close",
                    "family_id": "fam-close",
                    "broker": "vantage",
                    "platform": "mt5",
                    "broker_symbol": "GOLD",
                    "side": "buy",
                    "order_type": "market",
                    "lots": "0.02",
                    "requested_entry": "4662",
                    "sl_price": "4527",
                    "tp_price": "4690",
                    "magic": 123456,
                    "comment": "tradebot:fam-close:leg-close",
                }
            ]
        },
    )

    r = client.post("/close-legs", json={"leg_ids": ["leg-close"]})
    assert r.status_code == 200

    data = r.json()
    assert data["results"][0]["ok"] is True
    assert data["results"][0]["status"] == "closed"

    positions = client.get("/open-positions").json()["positions"]
    assert not any(p["leg_id"] == "leg-close" for p in positions)
