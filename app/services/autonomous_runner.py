from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timezone

from app.execution.node_health import check_execution_node_health
from app.execution.state_sync import sync_execution_state
from app.services.monitoring_summary import queue_monitoring_summary
from app.services.restart_recovery import recover_after_restart
from app.services.alerts import alert_execution_failure
from app.services.autonomous_execution import process_autonomous_executions


@dataclass(frozen=True)
class AutonomousCycleResult:
    broker: str
    platform: str
    ok: bool
    health_ok: bool
    terminal_connected: bool
    recovery_ran: bool
    sync_ran: bool
    execution_ran: bool
    executions_attempted: int
    executions_sent: int
    monitoring_queued: bool
    error: str | None
    started_at: str
    finished_at: str


def run_autonomous_cycle(
    *,
    broker: str,
    platform: str,
    run_recovery: bool = False,
    queue_monitoring: bool = True,
) -> AutonomousCycleResult:
    started = datetime.now(timezone.utc)

    try:
        health = check_execution_node_health(broker=broker, platform=platform)

        if not health.ok or not health.terminal_connected:
            return AutonomousCycleResult(
                broker=broker,
                platform=platform,
                ok=False,
                health_ok=health.ok,
                terminal_connected=health.terminal_connected,
                recovery_ran=False,
                sync_ran=False,
                execution_ran=False,
                executions_attempted=0,
                executions_sent=0,
                monitoring_queued=False,
                error="execution_node_unhealthy",
                started_at=started.isoformat(),
                finished_at=datetime.now(timezone.utc).isoformat(),
            )

        recovery_ran = False
        if run_recovery:
            recover_after_restart(broker=broker, platform=platform, queue_alert=True)
            recovery_ran = True

        execution_result = process_autonomous_executions(broker=broker, platform=platform)

        sync_execution_state(broker=broker, platform=platform)

        monitoring_queued = False
        if queue_monitoring:
            queue_monitoring_summary()
            monitoring_queued = True

        return AutonomousCycleResult(
            broker=broker,
            platform=platform,
            ok=True,
            health_ok=health.ok,
            terminal_connected=health.terminal_connected,
            recovery_ran=recovery_ran,
            sync_ran=True,
            execution_ran=True,
            executions_attempted=execution_result.attempted,
            executions_sent=execution_result.executed,
            monitoring_queued=monitoring_queued,
            error=None,
            started_at=started.isoformat(),
            finished_at=datetime.now(timezone.utc).isoformat(),
        )

    except Exception as exc:
        alert_execution_failure(
            message=f"Autonomous cycle failed: {exc}",
            broker=broker,
            platform=platform,
            data={"component": "autonomous_runner"},
        )

        return AutonomousCycleResult(
            broker=broker,
            platform=platform,
            ok=False,
            health_ok=False,
            terminal_connected=False,
            recovery_ran=False,
            sync_ran=False,
            execution_ran=False,
            executions_attempted=0,
            executions_sent=0,
            monitoring_queued=False,
            error=str(exc),
            started_at=started.isoformat(),
            finished_at=datetime.now(timezone.utc).isoformat(),
        )
