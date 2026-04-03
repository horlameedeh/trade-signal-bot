from __future__ import annotations

from dataclasses import dataclass
from decimal import Decimal, InvalidOperation
from typing import Optional

from sqlalchemy import text

from app.db.session import SessionLocal
from app.parsing.models import ParsedSignal


@dataclass(frozen=True)
class ApplyUpdateResult:
    family_id: str
    family_updated: bool
    legs_updated: int
    reason: str


def _to_decimal(value: Optional[str]) -> Optional[str]:
    if value is None:
        return None
    try:
        return str(Decimal(str(value).replace(",", "")))
    except (InvalidOperation, ValueError):
        return None


def apply_update_to_family(
    *,
    family_id: str,
    parsed: ParsedSignal,
) -> ApplyUpdateResult:
    """
    Applies parsed UPDATE to an existing trade_family + trade_legs.

    Supported:
    - move_sl_to_entry / move_sl_to_be -> set remaining legs SL = family.entry_price
    - move_sl_to_price -> set family + all open legs SL
    - move_tp_to_price -> update target leg TP
    - add_tps -> extend/update existing legs in order if needed
    """
    if not parsed.update:
        return ApplyUpdateResult(
            family_id=family_id,
            family_updated=False,
            legs_updated=0,
            reason="no_update_payload",
        )

    upd = parsed.update

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

        family_updated = False
        legs_updated = 0

        # 1) SL -> entry / BE
        if upd.move_sl_to_entry or upd.move_sl_to_be:
            entry_price = fam["entry_price"]
            if entry_price is not None:
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
                family_updated = True

                result = db.execute(
                    text(
                        """
                        UPDATE trade_legs
                        SET sl_price = :entry_price
                                                WHERE family_id = CAST(:family_id AS uuid)
                          AND state = 'OPEN'
                        """
                    ),
                    {"family_id": family_id, "entry_price": entry_price},
                )
                legs_updated += result.rowcount or 0

        # 2) Explicit SL price
        explicit_sl = _to_decimal(upd.move_sl_to_price)
        if explicit_sl is not None:
            db.execute(
                text(
                    """
                    UPDATE trade_families
                    SET sl_price = :sl_price,
                        updated_at = now()
                    WHERE family_id = CAST(:family_id AS uuid)
                    """
                ),
                {"family_id": family_id, "sl_price": explicit_sl},
            )
            family_updated = True

            result = db.execute(
                text(
                    """
                    UPDATE trade_legs
                    SET sl_price = :sl_price
                                        WHERE family_id = CAST(:family_id AS uuid)
                      AND state = 'OPEN'
                    """
                ),
                {"family_id": family_id, "sl_price": explicit_sl},
            )
            legs_updated += result.rowcount or 0

        # 3) Move specific TPn to price
        for tp_index, raw_price in (upd.move_tp_to_price or {}).items():
            price = _to_decimal(raw_price)
            if price is None:
                continue

            result = db.execute(
                text(
                    """
                    UPDATE trade_legs
                    SET tp_price = :tp_price
                                        WHERE family_id = CAST(:family_id AS uuid)
                      AND leg_index = :leg_index
                    """
                ),
                {"family_id": family_id, "leg_index": int(tp_index), "tp_price": price},
            )
            legs_updated += result.rowcount or 0

        # 4) Add/replace TP list for stub completion or explicit TP add
        #    Apply in order to existing legs; if more TPs than legs, create new legs with copied family prices.
        add_tps = [_to_decimal(x) for x in (upd.add_tps or [])]
        add_tps = [x for x in add_tps if x is not None]

        if add_tps:
            existing_legs = db.execute(
                text(
                    """
                    SELECT leg_index
                    FROM trade_legs
                    WHERE family_id = CAST(:family_id AS uuid)
                    ORDER BY leg_index
                    """
                ),
                {"family_id": family_id},
            ).scalars().all()

            fam_prices = db.execute(
                text(
                    """
                    SELECT entry_price::text AS entry_price, sl_price::text AS sl_price, plan_id::text AS plan_id
                    FROM trade_families
                    WHERE family_id = CAST(:family_id AS uuid)
                    """
                ),
                {"family_id": family_id},
            ).mappings().first()

            for idx, tp in enumerate(add_tps, start=1):
                if idx in existing_legs:
                    result = db.execute(
                        text(
                            """
                            UPDATE trade_legs
                            SET tp_price = :tp_price
                                                        WHERE family_id = CAST(:family_id AS uuid)
                              AND leg_index = :leg_index
                            """
                        ),
                        {"family_id": family_id, "leg_index": idx, "tp_price": tp},
                    )
                    legs_updated += result.rowcount or 0
                else:
                    db.execute(
                        text(
                            """
                            INSERT INTO trade_legs (
                              family_id,
                                                            plan_id,
                                                            idx,
                              leg_index,
                              entry_price,
                              sl_price,
                              tp_price,
                              state,
                                                            lots
                            )
                            VALUES (
                                                            CAST(:family_id AS uuid),
                                                            CAST(:plan_id AS uuid),
                                                            :idx,
                              :leg_index,
                              :entry_price,
                              :sl_price,
                              :tp_price,
                              'OPEN',
                                                            0.01
                            )
                            """
                        ),
                        {
                            "family_id": family_id,
                                                        "plan_id": fam_prices["plan_id"],
                                                        "idx": idx,
                            "leg_index": idx,
                            "entry_price": fam_prices["entry_price"],
                            "sl_price": fam_prices["sl_price"],
                            "tp_price": tp,
                        },
                    )
                    legs_updated += 1

            db.execute(
                text(
                    """
                    UPDATE trade_families
                    SET tp_count = GREATEST(tp_count, :tp_count),
                        updated_at = now()
                    WHERE family_id = CAST(:family_id AS uuid)
                    """
                ),
                {"family_id": family_id, "tp_count": len(add_tps)},
            )
            family_updated = True

        db.commit()

    return ApplyUpdateResult(
        family_id=family_id,
        family_updated=family_updated,
        legs_updated=legs_updated,
        reason="ok",
    )
