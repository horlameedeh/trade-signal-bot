from __future__ import annotations

from dataclasses import dataclass
from decimal import Decimal

from sqlalchemy import text

from app.db.session import SessionLocal


@dataclass(frozen=True)
class TradeMetrics:
    families_total: int
    families_open: int
    families_partially_closed: int
    families_closed: int
    legs_total: int
    legs_open: int
    legs_tp_hit: int
    legs_sl_hit: int
    legs_closed_manual: int
    win_rate_pct: str


@dataclass(frozen=True)
class ExecutionMetrics:
    tickets_total: int
    tickets_open: int
    tickets_closed: int
    execution_errors: int
    dead_letters: int
    retry_failures: int


@dataclass(frozen=True)
class LatencyMetrics:
    avg_seconds_to_ticket: str | None
    max_seconds_to_ticket: str | None


@dataclass(frozen=True)
class MonitoringSnapshot:
    trade: TradeMetrics
    execution: ExecutionMetrics
    latency: LatencyMetrics


def _scalar(db, sql: str, params: dict | None = None) -> int:
    return int(db.execute(text(sql), params or {}).scalar() or 0)


def _decimal_str(value) -> str | None:
    if value is None:
        return None
    return str(Decimal(str(value)).quantize(Decimal("0.01")))


def get_trade_metrics() -> TradeMetrics:
    with SessionLocal() as db:
        families_total = _scalar(db, "SELECT COUNT(*) FROM trade_families")
        families_open = _scalar(db, "SELECT COUNT(*) FROM trade_families WHERE state = 'OPEN'")
        families_partially_closed = _scalar(db, "SELECT COUNT(*) FROM trade_families WHERE state = 'PARTIALLY_CLOSED'")
        families_closed = _scalar(db, "SELECT COUNT(*) FROM trade_families WHERE state = 'CLOSED'")

        legs_total = _scalar(db, "SELECT COUNT(*) FROM trade_legs")
        legs_open = _scalar(db, "SELECT COUNT(*) FROM trade_legs WHERE state = 'OPEN'")
        legs_tp_hit = _scalar(db, "SELECT COUNT(*) FROM trade_legs WHERE state = 'TP_HIT'")
        legs_sl_hit = _scalar(db, "SELECT COUNT(*) FROM trade_legs WHERE state = 'SL_HIT'")
        legs_closed_manual = _scalar(db, "SELECT COUNT(*) FROM trade_legs WHERE state = 'CLOSED_MANUAL'")

    resolved = legs_tp_hit + legs_sl_hit
    win_rate = Decimal("0")
    if resolved > 0:
        win_rate = (Decimal(legs_tp_hit) / Decimal(resolved)) * Decimal("100")

    return TradeMetrics(
        families_total=families_total,
        families_open=families_open,
        families_partially_closed=families_partially_closed,
        families_closed=families_closed,
        legs_total=legs_total,
        legs_open=legs_open,
        legs_tp_hit=legs_tp_hit,
        legs_sl_hit=legs_sl_hit,
        legs_closed_manual=legs_closed_manual,
        win_rate_pct=str(win_rate.quantize(Decimal("0.01"))),
    )


def get_execution_metrics() -> ExecutionMetrics:
    with SessionLocal() as db:
        tickets_total = _scalar(db, "SELECT COUNT(*) FROM execution_tickets")
        tickets_open = _scalar(db, "SELECT COUNT(*) FROM execution_tickets WHERE status = 'open'")
        tickets_closed = _scalar(db, "SELECT COUNT(*) FROM execution_tickets WHERE status = 'closed'")
        execution_errors = _scalar(db, "SELECT COUNT(*) FROM control_actions WHERE action = 'alert:execution_failure'")
        dead_letters = _scalar(db, "SELECT COUNT(*) FROM control_actions WHERE action LIKE 'dead_letter:%'")
        retry_failures = _scalar(db, "SELECT COUNT(*) FROM control_actions WHERE action = 'execution_retry' AND status = 'failed'")

    return ExecutionMetrics(
        tickets_total=tickets_total,
        tickets_open=tickets_open,
        tickets_closed=tickets_closed,
        execution_errors=execution_errors,
        dead_letters=dead_letters,
        retry_failures=retry_failures,
    )


def get_latency_metrics() -> LatencyMetrics:
    with SessionLocal() as db:
        row = db.execute(
            text(
                """
                SELECT
                  AVG(EXTRACT(EPOCH FROM (et.created_at - tf.created_at))) AS avg_seconds_to_ticket,
                  MAX(EXTRACT(EPOCH FROM (et.created_at - tf.created_at))) AS max_seconds_to_ticket
                FROM execution_tickets et
                JOIN trade_families tf ON tf.family_id = et.family_id
                WHERE et.created_at IS NOT NULL
                  AND tf.created_at IS NOT NULL
                  AND et.created_at >= tf.created_at
                """
            )
        ).mappings().first()

    return LatencyMetrics(
        avg_seconds_to_ticket=_decimal_str(row["avg_seconds_to_ticket"] if row else None),
        max_seconds_to_ticket=_decimal_str(row["max_seconds_to_ticket"] if row else None),
    )


def get_monitoring_snapshot() -> MonitoringSnapshot:
    return MonitoringSnapshot(
        trade=get_trade_metrics(),
        execution=get_execution_metrics(),
        latency=get_latency_metrics(),
    )
