from __future__ import annotations

import json
from dataclasses import dataclass

from sqlalchemy import text

from app.db.session import SessionLocal
from app.execution.base import ExecutionAdapter, OrderLegRequest


@dataclass(frozen=True)
class LiveExecutionResult:
    family_id: str
    sent: int
    skipped_existing: int
    tickets_persisted: int


def _magic_for_family(family_id: str) -> int:
    return abs(hash(family_id)) % 900000 + 100000


def _load_open_leg_requests(family_id: str) -> list[OrderLegRequest]:
    with SessionLocal() as db:
        rows = db.execute(
            text(
                """
                SELECT
                  tl.leg_id::text AS leg_id,
                  tf.family_id::text AS family_id,
                  ba.broker,
                  ba.platform,
                  tf.broker_symbol,
                  tf.side,
                  ti.order_type::text AS order_type,
                  tl.lots::text AS lots,
                  tl.requested_entry::text AS requested_entry,
                  tl.sl_price::text AS sl_price,
                  tl.tp_price::text AS tp_price
                FROM trade_legs tl
                JOIN trade_families tf ON tf.family_id = tl.family_id
                JOIN trade_intents ti ON ti.intent_id = tf.intent_id
                JOIN broker_accounts ba ON ba.account_id = tf.account_id
                WHERE tf.family_id = CAST(:family_id AS uuid)
                  AND tl.state = 'OPEN'
                  AND NOT EXISTS (
                    SELECT 1
                    FROM execution_tickets et
                    WHERE et.leg_id = tl.leg_id
                  )
                ORDER BY tl.leg_index
                """
            ),
            {"family_id": family_id},
        ).mappings().all()

    magic = _magic_for_family(family_id)

    return [
        OrderLegRequest(
            leg_id=r["leg_id"],
            family_id=r["family_id"],
            broker=r["broker"],
            platform=r["platform"],
            broker_symbol=r["broker_symbol"],
            side=r["side"],
            order_type=r["order_type"] or "market",
            lots=r["lots"],
            requested_entry=r["requested_entry"],
            sl_price=r["sl_price"],
            tp_price=r["tp_price"],
            magic=magic,
            comment=f"tradebot:{r['family_id']}:{r['leg_id']}",
        )
        for r in rows
    ]


def execute_family_live(*, family_id: str, adapter: ExecutionAdapter) -> LiveExecutionResult:
    legs = _load_open_leg_requests(family_id)

    with SessionLocal() as db:
        total_open = db.execute(
            text("SELECT COUNT(*) FROM trade_legs WHERE family_id = CAST(:family_id AS uuid) AND state = 'OPEN'"),
            {"family_id": family_id},
        ).scalar() or 0

        existing = db.execute(
            text(
                """
                SELECT COUNT(*)
                FROM execution_tickets et
                JOIN trade_legs tl ON tl.leg_id = et.leg_id
                WHERE tl.family_id = CAST(:family_id AS uuid)
                """
            ),
            {"family_id": family_id},
        ).scalar() or 0

    if not legs:
        return LiveExecutionResult(
            family_id=family_id,
            sent=0,
            skipped_existing=int(existing),
            tickets_persisted=0,
        )

    receipts = adapter.open_legs(legs)

    by_leg = {leg.leg_id: leg for leg in legs}
    persisted = 0

    with SessionLocal() as db:
        for receipt in receipts:
            leg = by_leg[receipt.leg_id]

            db.execute(
                text(
                    """
                    INSERT INTO execution_tickets (
                      leg_id,
                      family_id,
                      broker,
                      platform,
                      broker_symbol,
                      broker_ticket,
                      side,
                      order_type,
                      requested_entry,
                      actual_fill_price,
                      sl_price,
                      tp_price,
                      lots,
                      status,
                      raw_response
                    )
                    VALUES (
                      CAST(:leg_id AS uuid),
                      CAST(:family_id AS uuid),
                      :broker,
                      :platform,
                      :broker_symbol,
                      :broker_ticket,
                      :side,
                      :order_type,
                      :requested_entry,
                      :actual_fill_price,
                      :sl_price,
                      :tp_price,
                      :lots,
                      :status,
                      CAST(:raw_response AS jsonb)
                    )
                    ON CONFLICT (leg_id) DO NOTHING
                    """
                ),
                {
                    "leg_id": receipt.leg_id,
                    "family_id": leg.family_id,
                    "broker": leg.broker,
                    "platform": leg.platform,
                    "broker_symbol": leg.broker_symbol,
                    "broker_ticket": receipt.broker_ticket,
                    "side": leg.side,
                    "order_type": leg.order_type,
                    "requested_entry": leg.requested_entry,
                    "actual_fill_price": receipt.actual_fill_price,
                    "sl_price": leg.sl_price,
                    "tp_price": leg.tp_price,
                    "lots": leg.lots,
                    "status": receipt.status,
                    "raw_response": json.dumps(receipt.raw, default=str),
                },
            )
            persisted += 1

        db.commit()

    return LiveExecutionResult(
        family_id=family_id,
        sent=len(legs),
        skipped_existing=int(existing),
        tickets_persisted=persisted,
    )
