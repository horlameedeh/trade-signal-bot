from __future__ import annotations

from dataclasses import dataclass

from sqlalchemy import text

from app.db.session import SessionLocal


@dataclass(frozen=True)
class ManagementResult:
    family_id: str
    legs_updated: int
    reason: str


def apply_be_at_tp1(*, family_id: str) -> ManagementResult:
    """
    Global management rule:
    When TP1 leg closes in profit, move SL to entry on remaining OPEN legs.
    """
    with SessionLocal() as db:
        fam = db.execute(
            text(
                """
                SELECT family_id::text, entry_price::text AS entry_price
                FROM trade_families
                WHERE family_id = CAST(:family_id AS uuid)
                LIMIT 1
                """
            ),
            {"family_id": family_id},
        ).mappings().first()

        if not fam:
            raise RuntimeError(f"trade_family not found: {family_id}")

        tp1 = db.execute(
            text(
                """
                SELECT state, tp_price::text AS tp_price, entry_price::text AS entry_price
                FROM trade_legs
                WHERE family_id = CAST(:family_id AS uuid)
                  AND leg_index = 1
                LIMIT 1
                """
            ),
            {"family_id": family_id},
        ).mappings().first()

        if not tp1:
            return ManagementResult(
                family_id=family_id,
                legs_updated=0,
                reason="no_tp1_leg",
            )

        # For Milestone 5 local logic, a closed TP1 leg is treated as "closed in profit"
        if tp1["state"] != "CLOSED":
            return ManagementResult(
                family_id=family_id,
                legs_updated=0,
                reason="tp1_not_closed",
            )

        entry_price = fam["entry_price"]
        if entry_price is None:
            return ManagementResult(
                family_id=family_id,
                legs_updated=0,
                reason="missing_entry_price",
            )

        result = db.execute(
            text(
                """
                UPDATE trade_legs
                SET sl_price = :entry_price
                WHERE family_id = CAST(:family_id AS uuid)
                  AND state = 'OPEN'
                  AND leg_index > 1
                """
            ),
            {"family_id": family_id, "entry_price": entry_price},
        )

        db.execute(
            text(
                """
                UPDATE trade_families
                SET sl_price = :entry_price,
                    updated_at = now()
                WHERE family_id = CAST(:family_id AS uuid)
                """
            ),
            {"family_id": family_id, "entry_price": entry_price},
        )

        db.commit()

    return ManagementResult(
        family_id=family_id,
        legs_updated=result.rowcount or 0,
        reason="be_at_tp1_applied",
    )
