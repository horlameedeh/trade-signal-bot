import pytest
import requests
from sqlalchemy import text

from app.db.session import SessionLocal
from app.execution.node_health import check_execution_node_health


pytestmark = pytest.mark.integration


@pytest.fixture
def db_session():
    with SessionLocal() as db:
        try:
            db.execute(text("DELETE FROM execution_nodes WHERE name = 'health-test-node' OR base_url = 'http://fake-node'"))
            db.execute(text("DELETE FROM control_actions WHERE action = 'alert:mt5_disconnected'"))
            db.commit()
            yield db
        finally:
            db.execute(text("DELETE FROM execution_nodes WHERE name = 'health-test-node' OR base_url = 'http://fake-node'"))
            db.execute(text("DELETE FROM control_actions WHERE action = 'alert:mt5_disconnected'"))
            db.commit()


def _seed_node(db_session):
    db_session.execute(
        text(
            """
            INSERT INTO execution_nodes (name, broker, platform, base_url, is_active, meta)
            VALUES ('health-test-node', 'ftmo', 'mt5', 'http://health-node', true, '{}'::jsonb)
            ON CONFLICT (broker, platform, name)
            DO UPDATE SET base_url = EXCLUDED.base_url, is_active = true
            """
        )
    )
    db_session.commit()


def _latest_health_alert(db_session):
    return db_session.execute(
        text(
            """
            SELECT action, payload
            FROM control_actions
            WHERE action = 'alert:mt5_disconnected'
            ORDER BY created_at DESC
            LIMIT 1
            """
        )
    ).mappings().first()


class FakeResponse:
    def __init__(self, payload):
        self.payload = payload

    def raise_for_status(self):
        return None

    def json(self):
        return self.payload


def test_health_check_ok_does_not_alert(monkeypatch, db_session):
    _seed_node(db_session)

    def fake_get(url, timeout):
        return FakeResponse(
            {
                "ok": True,
                "terminal_connected": True,
                "trading_enabled": False,
                "detail": "account=demo",
            }
        )

    monkeypatch.setattr(requests, "get", fake_get)

    result = check_execution_node_health(broker="ftmo", platform="mt5")

    assert result.ok is True
    assert result.terminal_connected is True
    assert result.alert_queued is False
    assert _latest_health_alert(db_session) is None


def test_health_check_unhealthy_queues_alert(monkeypatch, db_session):
    _seed_node(db_session)

    def fake_get(url, timeout):
        return FakeResponse(
            {
                "ok": False,
                "terminal_connected": False,
                "trading_enabled": False,
                "detail": "MT5 initialize failed",
            }
        )

    monkeypatch.setattr(requests, "get", fake_get)

    result = check_execution_node_health(broker="ftmo", platform="mt5")

    assert result.ok is False
    assert result.alert_queued is True

    alert = _latest_health_alert(db_session)
    assert alert is not None
    assert alert["payload"]["category"] == "mt5_disconnected"
    assert "MT5 initialize failed" in alert["payload"]["formatted"]


def test_health_check_network_error_queues_alert(monkeypatch, db_session):
    _seed_node(db_session)

    def fake_get(url, timeout):
        raise requests.Timeout("timed out")

    monkeypatch.setattr(requests, "get", fake_get)

    result = check_execution_node_health(broker="ftmo", platform="mt5")

    assert result.ok is False
    assert result.alert_queued is True

    alert = _latest_health_alert(db_session)
    assert alert is not None
    assert "timed out" in alert["payload"]["formatted"]
