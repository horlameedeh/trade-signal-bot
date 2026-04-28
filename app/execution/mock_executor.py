from __future__ import annotations

from dataclasses import dataclass

from sqlalchemy import text

from app.db.session import SessionLocal


@dataclass(frozen=True)
class MockExecutionResult:
    family_id: str
    legs_planned: int
    duplicate_legs_skipped: int


def plan_family_execution(*, family_id: str) -> MockExecutionResult:
    with SessionLocal() as db:
        family = db.execute(
            text(
                """
                SELECT
                  tf.family_id::text AS family_id,
                  tf.source_msg_pk::text AS source_msg_pk,
                  tf.broker_symbol,
                  tf.side,
                  ba.broker,
                  ba.platform
                FROM trade_families tf
                LEFT JOIN broker_accounts ba ON ba.account_id = tf.account_id
                WHERE tf.family_id = CAST(:family_id AS uuid)
                LIMIT 1
                """
            ),
            {"family_id": family_id},
        ).mappings().first()

        if not family:
            raise RuntimeError(f"trade_family not found: {family_id}")

        legs = db.execute(
            text(
                """
                SELECT
                  leg_id::text AS leg_id,
                  family_id::text AS family_id,
                  requested_entry::text AS requested_entry,
                  tp_price::text AS tp_price,
                  sl_price::text AS sl_price,
                  lots::text AS lots,
                  placement_delay_ms,
                  entry_price::text AS entry_price
                FROM trade_legs
                WHERE family_id = CAST(:family_id AS uuid)
                ORDER BY leg_index
                """
            ),
            {"family_id": family_id},
        ).mappings().all()

        planned = 0
        skipped = 0

        for leg in legs:
            exists = db.execute(
                text(
                    """
                    SELECT 1
                    FROM mock_executions
                    WHERE leg_id = CAST(:leg_id AS uuid)
                    LIMIT 1
                    """
                ),
                {"leg_id": leg["leg_id"]},
            ).scalar()

            if exists:
                skipped += 1
                continue

            db.execute(
                text(
                    """
                    INSERT INTO mock_executions (
                      family_id,
                      leg_id,
                      source_msg_pk,
                      broker,
                      platform,
                      broker_symbol,
                      order_type,
                      side,
                      requested_entry,
                      tp_price,
                      sl_price,
                      lots,
                      placement_delay_ms,
                      status,
                      meta
                    )
                    VALUES (
                      CAST(:family_id AS uuid),
                      CAST(:leg_id AS uuid),
                      CAST(:source_msg_pk AS uuid),
                      :broker,
                      :platform,
                      :broker_symbol,
                      :order_type,
                      :side,
                      :requested_entry,
                      :tp_price,
                      :sl_price,
                      :lots,
                      :placement_delay_ms,
                      'planned',
                      '{}'::jsonb
                    )
                    """
                ),
                {
                    "family_id": family["family_id"],
                    "leg_id": leg["leg_id"],
                    "source_msg_pk": family["source_msg_pk"],
                    "broker": family["broker"],
                    "platform": family["platform"],
                    "broker_symbol": family["broker_symbol"],
                    "order_type": "market",
                    "side": family["side"],
                    "requested_entry": leg["requested_entry"] or leg["entry_price"],
                    "tp_price": leg["tp_price"],
                    "sl_price": leg["sl_price"],
                    "lots": leg["lots"],
                    "placement_delay_ms": leg["placement_delay_ms"] or 0,
                },
            )
            planned += 1

        db.commit()

    return MockExecutionResult(
        family_id=family_id,
        legs_planned=planned,
        duplicate_legs_skipped=skipped,
    )
