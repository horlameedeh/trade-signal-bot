from __future__ import annotations

from dataclasses import dataclass

from sqlalchemy import text

from app.db.session import SessionLocal
from app.execution.ticket_ops import modify_legs_sl_tp_live
from app.services.alerts import alert_management_action


@dataclass(frozen=True)
class LiveManagementResult:
    family_id: str
    rule: str
    triggered: bool
    legs_modified: int
    reason: str


def _be_rule_enabled(management_rules) -> bool:
    if not management_rules:
        return False
    return bool(
        management_rules.get("BE_AT_TP1")
        or management_rules.get("SL_TO_ENTRY_AT_TP1")
    )


def apply_live_be_at_tp1(*, family_id: str) -> LiveManagementResult:
    """
    If TP1 is hit, move SL to entry for all remaining OPEN legs.

    Idempotency:
    - skip if family.meta.management_applied.BE_AT_TP1 is true
    - skip legs already at entry
    """
    with SessionLocal() as db:
        family = db.execute(
            text(
                """
                SELECT
                  family_id::text AS family_id,
                  entry_price::text AS entry_price,
                  management_rules,
                  meta
                FROM trade_families
                WHERE family_id = CAST(:family_id AS uuid)
                LIMIT 1
                """
            ),
            {"family_id": family_id},
        ).mappings().first()

        if not family:
            return LiveManagementResult(
                family_id=family_id,
                rule="BE_AT_TP1",
                triggered=False,
                legs_modified=0,
                reason="family_not_found",
            )

        if not _be_rule_enabled(family["management_rules"]):
            return LiveManagementResult(
                family_id=family_id,
                rule="BE_AT_TP1",
                triggered=False,
                legs_modified=0,
                reason="rule_not_enabled",
            )

        meta = family["meta"] or {}
        applied = (meta.get("management_applied") or {}).get("BE_AT_TP1")
        if applied:
            return LiveManagementResult(
                family_id=family_id,
                rule="BE_AT_TP1",
                triggered=False,
                legs_modified=0,
                reason="already_applied",
            )

        tp1_hit = db.execute(
            text(
                """
                SELECT 1
                FROM trade_legs
                WHERE family_id = CAST(:family_id AS uuid)
                  AND leg_index = 1
                  AND state = 'TP_HIT'
                LIMIT 1
                """
            ),
            {"family_id": family_id},
        ).scalar()

        if not tp1_hit:
            return LiveManagementResult(
                family_id=family_id,
                rule="BE_AT_TP1",
                triggered=False,
                legs_modified=0,
                reason="tp1_not_hit",
            )

        open_leg_rows = db.execute(
            text(
                """
                SELECT leg_id::text
                FROM trade_legs
                WHERE family_id = CAST(:family_id AS uuid)
                  AND state = 'OPEN'
                  AND leg_index > 1
                  AND COALESCE(sl_price, 0) <> CAST(:entry_price AS numeric)
                ORDER BY leg_index
                """
            ),
            {"family_id": family_id, "entry_price": family["entry_price"]},
        ).mappings().all()

    leg_ids = [r["leg_id"] for r in open_leg_rows]
    if not leg_ids:
        with SessionLocal() as db:
            db.execute(
                text(
                    """
                    UPDATE trade_families
                    SET meta = (meta::jsonb || jsonb_build_object(
                        'management_applied',
                        COALESCE(meta::jsonb->'management_applied', '{}'::jsonb)
                        || jsonb_build_object('BE_AT_TP1', true)
                    ))::json,
                    updated_at = now()
                    WHERE family_id = CAST(:family_id AS uuid)
                    """
                ),
                {"family_id": family_id},
            )
            db.commit()

        return LiveManagementResult(
            family_id=family_id,
            rule="BE_AT_TP1",
            triggered=True,
            legs_modified=0,
            reason="no_open_legs_to_modify",
        )

    modify_result = modify_legs_sl_tp_live(
        leg_ids=leg_ids,
        sl=family["entry_price"],
        tp=None,
    )

    with SessionLocal() as db:
        if modify_result.ok > 0:
            db.execute(
                text(
                    """
                    UPDATE trade_legs
                    SET sl_price = CAST(:entry_price AS numeric)
                    WHERE leg_id = ANY(CAST(:leg_ids AS uuid[]))
                    """
                ),
                {
                    "entry_price": family["entry_price"],
                    "leg_ids": "{" + ",".join(leg_ids) + "}",
                },
            )

        if modify_result.failed == 0:
            db.execute(
                text(
                    """
                    UPDATE trade_families
                    SET meta = (meta::jsonb || jsonb_build_object(
                        'management_applied',
                        COALESCE(meta::jsonb->'management_applied', '{}'::jsonb)
                        || jsonb_build_object('BE_AT_TP1', true)
                    ))::json,
                    updated_at = now()
                    WHERE family_id = CAST(:family_id AS uuid)
                    """
                ),
                {"family_id": family_id},
            )

        db.commit()

    reason = "be_at_tp1_applied" if modify_result.failed == 0 else "partial_failure"

    if modify_result.ok > 0:
        alert_management_action(
            family_id=family_id,
            message="BE_AT_TP1 applied: moved remaining open legs SL to entry.",
            data={
                "rule": "BE_AT_TP1",
                "legs_modified": modify_result.ok,
                "failed": modify_result.failed,
                "reason": reason,
            },
        )

    return LiveManagementResult(
        family_id=family_id,
        rule="BE_AT_TP1",
        triggered=True,
        legs_modified=modify_result.ok,
        reason=reason,
    )
