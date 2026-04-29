from __future__ import annotations

import json
from dataclasses import dataclass

from sqlalchemy import text

from app.db.session import SessionLocal
from app.execution.http_node import HttpExecutionNode
from app.execution.node_registry import get_active_execution_node


@dataclass(frozen=True)
class ReconciliationResult:
    broker: str
    platform: str
    positions_seen: int
    tradebot_positions: int
    tickets_inserted: int
    tickets_updated: int
    unmatched_positions: int


def _extract_ids_from_comment(comment: str | None) -> tuple[str | None, str | None]:
    if not comment:
        return None, None

    # Expected full format:
    # tradebot:<family_id>:<leg_id>
    if comment.startswith("tradebot:"):
        parts = comment.split(":")
        if len(parts) >= 3:
            return parts[1], parts[2]

    # Smoke format intentionally does not map to DB.
    return None, None


def reconcile_open_positions(*, broker: str, platform: str) -> ReconciliationResult:
    node = get_active_execution_node(broker=broker, platform=platform)
    adapter = HttpExecutionNode(node.base_url)

    positions = adapter.query_open_positions()

    tradebot_positions = 0
    inserted = 0
    updated = 0
    unmatched = 0

    with SessionLocal() as db:
        for pos in positions:
            comment = pos.get("comment")
            family_id = pos.get("family_id")
            leg_id = pos.get("leg_id")

            if not family_id or not leg_id:
                parsed_family_id, parsed_leg_id = _extract_ids_from_comment(comment)
                family_id = family_id or parsed_family_id
                leg_id = leg_id or parsed_leg_id

            if not family_id or not leg_id:
                unmatched += 1
                continue

            tradebot_positions += 1

            leg_exists = db.execute(
                text(
                    """
                    SELECT 1
                    FROM trade_legs
                    WHERE leg_id = CAST(:leg_id AS uuid)
                      AND family_id = CAST(:family_id AS uuid)
                    LIMIT 1
                    """
                ),
                {"leg_id": leg_id, "family_id": family_id},
            ).scalar()

            if not leg_exists:
                unmatched += 1
                continue

            existing = db.execute(
                text(
                    """
                    SELECT ticket_id
                    FROM execution_tickets
                    WHERE leg_id = CAST(:leg_id AS uuid)
                    LIMIT 1
                    """
                ),
                {"leg_id": leg_id},
            ).scalar()

            if existing:
                db.execute(
                    text(
                        """
                        UPDATE execution_tickets
                        SET broker_ticket = :broker_ticket,
                            broker_symbol = :broker_symbol,
                            actual_fill_price = :actual_fill_price,
                            sl_price = :sl_price,
                            tp_price = :tp_price,
                            lots = :lots,
                            status = 'open',
                            raw_response = CAST(raw_response AS jsonb) || CAST(:raw AS jsonb),
                            updated_at = now()
                        WHERE leg_id = CAST(:leg_id AS uuid)
                        """
                    ),
                    {
                        "leg_id": leg_id,
                        "broker_ticket": str(pos["broker_ticket"]),
                        "broker_symbol": pos["broker_symbol"],
                        "actual_fill_price": pos.get("open_price"),
                        "sl_price": pos.get("sl_price") or None,
                        "tp_price": pos.get("tp_price") or None,
                        "lots": pos.get("lots"),
                        "raw": json.dumps({"reconciled": True, "position": pos}, default=str),
                    },
                )
                updated += 1
            else:
                side = pos.get("side") or "buy"

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
                        SELECT
                          tl.leg_id,
                          tl.family_id,
                          :broker,
                          :platform,
                          :broker_symbol,
                          :broker_ticket,
                          :side,
                          COALESCE(ti.order_type::text, 'market'),
                          tl.requested_entry,
                          :actual_fill_price,
                          :sl_price,
                          :tp_price,
                          :lots,
                          'open',
                          CAST(:raw AS jsonb)
                        FROM trade_legs tl
                        JOIN trade_families tf ON tf.family_id = tl.family_id
                        JOIN trade_intents ti ON ti.intent_id = tf.intent_id
                        WHERE tl.leg_id = CAST(:leg_id AS uuid)
                          AND tl.family_id = CAST(:family_id AS uuid)
                        ON CONFLICT (leg_id) DO NOTHING
                        """
                    ),
                    {
                        "leg_id": leg_id,
                        "family_id": family_id,
                        "broker": broker,
                        "platform": platform,
                        "broker_symbol": pos["broker_symbol"],
                        "broker_ticket": str(pos["broker_ticket"]),
                        "side": side,
                        "actual_fill_price": pos.get("open_price"),
                        "sl_price": pos.get("sl_price") or None,
                        "tp_price": pos.get("tp_price") or None,
                        "lots": pos.get("lots"),
                        "raw": json.dumps({"reconciled": True, "position": pos}, default=str),
                    },
                )
                inserted += 1

        db.commit()

    return ReconciliationResult(
        broker=broker,
        platform=platform,
        positions_seen=len(positions),
        tradebot_positions=tradebot_positions,
        tickets_inserted=inserted,
        tickets_updated=updated,
        unmatched_positions=unmatched,
    )
