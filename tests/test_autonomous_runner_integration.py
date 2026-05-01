import pytest

from app.services.autonomous_runner import run_autonomous_cycle


pytestmark = pytest.mark.integration


def test_autonomous_cycle_success(monkeypatch):
    class Health:
        ok = True
        terminal_connected = True

    calls = {
        "health": 0,
        "recovery": 0,
        "sync": 0,
        "monitoring": 0,
    }

    def fake_health(*, broker, platform):
        calls["health"] += 1
        return Health()

    def fake_recovery(*, broker, platform, queue_alert):
        calls["recovery"] += 1

    def fake_sync(*, broker, platform):
        calls["sync"] += 1

    def fake_monitoring():
        calls["monitoring"] += 1

    monkeypatch.setattr("app.services.autonomous_runner.check_execution_node_health", fake_health)
    monkeypatch.setattr("app.services.autonomous_runner.recover_after_restart", fake_recovery)
    monkeypatch.setattr("app.services.autonomous_runner.sync_execution_state", fake_sync)
    monkeypatch.setattr("app.services.autonomous_runner.queue_monitoring_summary", fake_monitoring)

    result = run_autonomous_cycle(
        broker="ftmo",
        platform="mt5",
        run_recovery=True,
        queue_monitoring=True,
    )

    assert result.ok is True
    assert result.health_ok is True
    assert result.terminal_connected is True
    assert result.recovery_ran is True
    assert result.sync_ran is True
    assert result.monitoring_queued is True
    assert calls == {
        "health": 1,
        "recovery": 1,
        "sync": 1,
        "monitoring": 1,
    }


def test_autonomous_cycle_stops_when_node_unhealthy(monkeypatch):
    class Health:
        ok = False
        terminal_connected = False

    calls = {"sync": 0}

    def fake_health(*, broker, platform):
        return Health()

    def fake_sync(*, broker, platform):
        calls["sync"] += 1

    monkeypatch.setattr("app.services.autonomous_runner.check_execution_node_health", fake_health)
    monkeypatch.setattr("app.services.autonomous_runner.sync_execution_state", fake_sync)

    result = run_autonomous_cycle(
        broker="ftmo",
        platform="mt5",
        run_recovery=True,
        queue_monitoring=True,
    )

    assert result.ok is False
    assert result.error == "execution_node_unhealthy"
    assert calls["sync"] == 0


def test_autonomous_cycle_failure_queues_alert(monkeypatch):
    calls = {"alert": 0}

    def fake_health(*, broker, platform):
        raise RuntimeError("boom")

    def fake_alert(**kwargs):
        calls["alert"] += 1

    monkeypatch.setattr("app.services.autonomous_runner.check_execution_node_health", fake_health)
    monkeypatch.setattr("app.services.autonomous_runner.alert_execution_failure", fake_alert)

    result = run_autonomous_cycle(broker="ftmo", platform="mt5")

    assert result.ok is False
    assert "boom" in result.error
    assert calls["alert"] == 1
