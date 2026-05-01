from __future__ import annotations

from dataclasses import asdict

from app.services.alerts import AlertPayload, queue_control_alert
from app.services.metrics import get_monitoring_snapshot


def format_monitoring_summary() -> str:
    snap = get_monitoring_snapshot()
    data = asdict(snap)

    trade = data["trade"]
    execution = data["execution"]
    latency = data["latency"]

    return (
        "📊 TradeBot Monitoring Summary\n\n"
        "Trades\n"
        f"- Families: {trade['families_total']} total / {trade['families_open']} open / "
        f"{trade['families_partially_closed']} partial / {trade['families_closed']} closed\n"
        f"- Legs: {trade['legs_total']} total / {trade['legs_open']} open\n"
        f"- Outcomes: TP={trade['legs_tp_hit']} SL={trade['legs_sl_hit']} Manual={trade['legs_closed_manual']}\n"
        f"- Win rate: {trade['win_rate_pct']}%\n\n"
        "Execution\n"
        f"- Tickets: {execution['tickets_total']} total / {execution['tickets_open']} open / {execution['tickets_closed']} closed\n"
        f"- Execution errors: {execution['execution_errors']}\n"
        f"- Dead letters: {execution['dead_letters']}\n"
        f"- Retry failures: {execution['retry_failures']}\n\n"
        "Latency\n"
        f"- Avg seconds to ticket: {latency['avg_seconds_to_ticket']}\n"
        f"- Max seconds to ticket: {latency['max_seconds_to_ticket']}"
    )


def queue_monitoring_summary() -> None:
    snap = get_monitoring_snapshot()

    queue_control_alert(
        AlertPayload(
            category="management_action",
            severity="info",
            title="TradeBot Monitoring Summary",
            message=format_monitoring_summary(),
            data=asdict(snap),
        )
    )
