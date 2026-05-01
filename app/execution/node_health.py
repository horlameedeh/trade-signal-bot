from __future__ import annotations

from dataclasses import dataclass

import requests

from app.execution.node_registry import get_active_execution_node
from app.services.alerts import alert_mt5_disconnected


@dataclass(frozen=True)
class NodeHealthCheckResult:
    broker: str
    platform: str
    ok: bool
    terminal_connected: bool
    trading_enabled: bool
    alert_queued: bool
    detail: str


def check_execution_node_health(*, broker: str, platform: str, timeout: float = 5.0) -> NodeHealthCheckResult:
    node = get_active_execution_node(broker=broker, platform=platform)

    try:
        response = requests.get(f"{node.base_url}/health", timeout=timeout)
        response.raise_for_status()
        data = response.json()
    except Exception as exc:
        alert_mt5_disconnected(
            broker=broker,
            platform=platform,
            detail=f"Execution node health check failed: {exc}",
        )
        return NodeHealthCheckResult(
            broker=broker,
            platform=platform,
            ok=False,
            terminal_connected=False,
            trading_enabled=False,
            alert_queued=True,
            detail=str(exc),
        )

    ok = bool(data.get("ok"))
    terminal_connected = bool(data.get("terminal_connected"))
    trading_enabled = bool(data.get("trading_enabled"))
    detail = str(data.get("detail") or "")

    if not ok or not terminal_connected:
        alert_mt5_disconnected(
            broker=broker,
            platform=platform,
            detail=f"Execution node unhealthy: ok={ok}, terminal_connected={terminal_connected}, detail={detail}",
        )
        return NodeHealthCheckResult(
            broker=broker,
            platform=platform,
            ok=ok,
            terminal_connected=terminal_connected,
            trading_enabled=trading_enabled,
            alert_queued=True,
            detail=detail,
        )

    return NodeHealthCheckResult(
        broker=broker,
        platform=platform,
        ok=ok,
        terminal_connected=terminal_connected,
        trading_enabled=trading_enabled,
        alert_queued=False,
        detail=detail,
    )
