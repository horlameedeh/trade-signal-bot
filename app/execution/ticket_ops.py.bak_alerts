from __future__ import annotations

from dataclasses import dataclass

from sqlalchemy import text

from app.db.session import SessionLocal
from app.execution.http_node import HttpExecutionNode
from app.execution.node_registry import get_active_execution_node


@dataclass(frozen=True)
class TicketOpResult:
    requested: int
    ok: int
    failed: int
    results: list[dict]


def _load_ticket_rows(leg_ids: list[str]) -> list[dict]:
    if not leg_ids:
        return []

    with SessionLocal() as db:
        rows = db.execute(
            text(
                """
                SELECT
                  et.leg_id::text AS leg_id,
                  et.broker_ticket,
                  et.broker_symbol,
                  et.broker,
                  et.platform,
                  et.side,
                  et.lots::text AS lots
                FROM execution_tickets et
                WHERE et.leg_id = ANY(CAST(:leg_ids AS uuid[]))
                  AND et.status = 'open'
                ORDER BY et.created_at ASC
                """
            ),
            {"leg_ids": "{" + ",".join(leg_ids) + "}"},
        ).mappings().all()

    return [dict(r) for r in rows]


def modify_legs_sl_tp_live(*, leg_ids: list[str], sl: str | None, tp: str | None) -> TicketOpResult:
    rows = _load_ticket_rows(leg_ids)
    if not rows:
        return TicketOpResult(requested=len(leg_ids), ok=0, failed=len(leg_ids), results=[])

    broker = rows[0]["broker"]
    platform = rows[0]["platform"]
    node = get_active_execution_node(broker=broker, platform=platform)
    adapter = HttpExecutionNode(node.base_url)

    payload = [
        {
            "leg_id": r["leg_id"],
            "broker_ticket": r["broker_ticket"],
            "broker_symbol": r["broker_symbol"],
            "sl": sl,
            "tp": tp,
        }
        for r in rows
    ]

    results = adapter.modify_ticket_sl_tp(payload)

    ok_count = sum(1 for r in results if r.get("ok") is True)

    with SessionLocal() as db:
        for r in results:
            if r.get("ok") is True:
                db.execute(
                    text(
                        """
                        UPDATE execution_tickets
                        SET sl_price = COALESCE(:sl, sl_price),
                            tp_price = COALESCE(:tp, tp_price),
                            updated_at = now(),
                            raw_response = (raw_response::jsonb || CAST(:raw AS jsonb))::json
                        WHERE leg_id = CAST(:leg_id AS uuid)
                        """
                    ),
                    {
                        "leg_id": r["leg_id"],
                        "sl": sl,
                        "tp": tp,
                        "raw": '{"last_modify":"ok"}',
                    },
                )
        db.commit()

    return TicketOpResult(
        requested=len(leg_ids),
        ok=ok_count,
        failed=len(leg_ids) - ok_count,
        results=results,
    )


def close_legs_live(*, leg_ids: list[str]) -> TicketOpResult:
    rows = _load_ticket_rows(leg_ids)
    if not rows:
        return TicketOpResult(requested=len(leg_ids), ok=0, failed=len(leg_ids), results=[])

    broker = rows[0]["broker"]
    platform = rows[0]["platform"]
    node = get_active_execution_node(broker=broker, platform=platform)
    adapter = HttpExecutionNode(node.base_url)

    payload = [
        {
            "leg_id": r["leg_id"],
            "broker_ticket": r["broker_ticket"],
            "broker_symbol": r["broker_symbol"],
            "side": r["side"],
            "lots": r["lots"],
        }
        for r in rows
    ]

    results = adapter.close_tickets(payload)
    ok_count = sum(1 for r in results if r.get("ok") is True)

    with SessionLocal() as db:
        for r in results:
            if r.get("ok") is True:
                db.execute(
                    text(
                        """
                        UPDATE execution_tickets
                        SET status = 'closed',
                            updated_at = now(),
                            raw_response = (raw_response::jsonb || CAST(:raw AS jsonb))::json
                        WHERE leg_id = CAST(:leg_id AS uuid)
                        """
                    ),
                    {"leg_id": r["leg_id"], "raw": '{"last_close":"ok"}'},
                )
                db.execute(
                    text(
                        """
                        UPDATE trade_legs
                        SET state = 'CLOSED'
                        WHERE leg_id = CAST(:leg_id AS uuid)
                        """
                    ),
                    {"leg_id": r["leg_id"]},
                )
        db.commit()

    return TicketOpResult(
        requested=len(leg_ids),
        ok=ok_count,
        failed=len(leg_ids) - ok_count,
        results=results,
    )
