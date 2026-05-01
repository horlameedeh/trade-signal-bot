from __future__ import annotations

import json
from dataclasses import dataclass
from typing import Any, Literal

from sqlalchemy import text

from app.db.session import SessionLocal


AlertSeverity = Literal["info", "warning", "critical"]
AlertCategory = Literal[
    "execution_failure",
    "missing_symbol_mapping",
    "reconciliation_mismatch",
    "mt5_disconnected",
    "trade_opened",
    "sl_tp_modified",
    "trade_closed",
    "risk_block",
    "risk_requires_approval",
    "management_action",
]


@dataclass(frozen=True)
class AlertPayload:
    category: AlertCategory
    severity: AlertSeverity
    title: str
    message: str
    family_id: str | None = None
    leg_id: str | None = None
    broker: str | None = None
    platform: str | None = None
    symbol: str | None = None
    action_required: str | None = None
    data: dict[str, Any] | None = None


@dataclass(frozen=True)
class AlertResult:
    queued: bool
    action: str
    category: str
    severity: str


def format_alert_message(alert: AlertPayload) -> str:
    lines = [
        f"🚨 {alert.title}" if alert.severity == "critical" else f"ℹ️ {alert.title}" if alert.severity == "info" else f"⚠️ {alert.title}",
        "",
        alert.message,
    ]

    details: list[str] = []
    if alert.broker:
        details.append(f"Broker: {alert.broker}")
    if alert.platform:
        details.append(f"Platform: {alert.platform}")
    if alert.symbol:
        details.append(f"Symbol: {alert.symbol}")
    if alert.family_id:
        details.append(f"Family: {alert.family_id}")
    if alert.leg_id:
        details.append(f"Leg: {alert.leg_id}")

    if details:
        lines.append("")
        lines.extend(details)

    if alert.action_required:
        lines.append("")
        lines.append(f"Action required: {alert.action_required}")

    return "\n".join(lines)


def queue_control_alert(alert: AlertPayload) -> AlertResult:
    formatted = format_alert_message(alert)

    with SessionLocal() as db:
        db.execute(
            text(
                """
                INSERT INTO control_actions (action, status, payload)
                VALUES (
                  :action,
                  'queued',
                  jsonb_build_object(
                    'source', 'alert_service',
                    'category', CAST(:category AS text),
                    'severity', CAST(:severity AS text),
                    'title', CAST(:title AS text),
                    'message', CAST(:message AS text),
                    'formatted', CAST(:formatted AS text),
                    'family_id', CAST(:family_id AS text),
                    'leg_id', CAST(:leg_id AS text),
                    'broker', CAST(:broker AS text),
                    'platform', CAST(:platform AS text),
                    'symbol', CAST(:symbol AS text),
                    'action_required', CAST(:action_required AS text),
                    'data', CAST(:data AS jsonb)
                  )
                )
                """
            ),
            {
                "action": f"alert:{alert.category}",
                "category": alert.category,
                "severity": alert.severity,
                "title": alert.title,
                "message": alert.message,
                "formatted": formatted,
                "family_id": alert.family_id,
                "leg_id": alert.leg_id,
                "broker": alert.broker,
                "platform": alert.platform,
                "symbol": alert.symbol,
                "action_required": alert.action_required,
                "data": json.dumps(alert.data or {}),
            },
        )
        db.commit()

    return AlertResult(
        queued=True,
        action=f"alert:{alert.category}",
        category=alert.category,
        severity=alert.severity,
    )


def alert_execution_failure(*, message: str, family_id: str | None = None, broker: str | None = None, platform: str | None = None, symbol: str | None = None, data: dict[str, Any] | None = None) -> AlertResult:
    return queue_control_alert(
        AlertPayload(
            category="execution_failure",
            severity="critical",
            title="Execution Failure",
            message=message,
            family_id=family_id,
            broker=broker,
            platform=platform,
            symbol=symbol,
            action_required="Review execution logs and decide whether to retry or reject.",
            data=data,
        )
    )


def alert_missing_symbol_mapping(*, symbol: str, broker: str, platform: str, data: dict[str, Any] | None = None) -> AlertResult:
    return queue_control_alert(
        AlertPayload(
            category="missing_symbol_mapping",
            severity="critical",
            title="Missing Symbol Mapping",
            message=f"No broker symbol mapping exists for {symbol}. Trade was blocked.",
            broker=broker,
            platform=platform,
            symbol=symbol,
            action_required="Add symbol mapping before allowing execution.",
            data=data,
        )
    )


def alert_reconciliation_mismatch(*, message: str, broker: str, platform: str, family_id: str | None = None, data: dict[str, Any] | None = None) -> AlertResult:
    return queue_control_alert(
        AlertPayload(
            category="reconciliation_mismatch",
            severity="warning",
            title="Reconciliation Mismatch",
            message=message,
            family_id=family_id,
            broker=broker,
            platform=platform,
            action_required="Review broker positions vs local DB state.",
            data=data,
        )
    )


def alert_mt5_disconnected(*, broker: str, platform: str, detail: str) -> AlertResult:
    return queue_control_alert(
        AlertPayload(
            category="mt5_disconnected",
            severity="critical",
            title="MT5 Disconnected",
            message=detail,
            broker=broker,
            platform=platform,
            action_required="Check Windows node, MT5 terminal, login session, and network.",
        )
    )


def alert_trade_opened(*, family_id: str, broker: str, platform: str, symbol: str, data: dict[str, Any] | None = None) -> AlertResult:
    return queue_control_alert(
        AlertPayload(
            category="trade_opened",
            severity="info",
            title="Trade Opened",
            message="Trade legs were opened successfully.",
            family_id=family_id,
            broker=broker,
            platform=platform,
            symbol=symbol,
            data=data,
        )
    )


def alert_sl_tp_modified(*, family_id: str, broker: str, platform: str, symbol: str | None = None, data: dict[str, Any] | None = None) -> AlertResult:
    return queue_control_alert(
        AlertPayload(
            category="sl_tp_modified",
            severity="info",
            title="SL/TP Modified",
            message="Stop loss / take profit modification completed.",
            family_id=family_id,
            broker=broker,
            platform=platform,
            symbol=symbol,
            data=data,
        )
    )


def alert_trade_closed(*, family_id: str, broker: str, platform: str, symbol: str | None = None, data: dict[str, Any] | None = None) -> AlertResult:
    return queue_control_alert(
        AlertPayload(
            category="trade_closed",
            severity="info",
            title="Trade Closed",
            message="Trade is now closed or no longer open at broker.",
            family_id=family_id,
            broker=broker,
            platform=platform,
            symbol=symbol,
            data=data,
        )
    )


def alert_management_action(*, family_id: str, message: str, data: dict[str, Any] | None = None) -> AlertResult:
    return queue_control_alert(
        AlertPayload(
            category="management_action",
            severity="info",
            title="Management Action Applied",
            message=message,
            family_id=family_id,
            data=data,
        )
    )
