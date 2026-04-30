from __future__ import annotations

from dataclasses import dataclass
from decimal import Decimal

from sqlalchemy import text

from app.db.session import SessionLocal


CLOSED_STATES = {"CLOSED", "TP_HIT", "SL_HIT", "CLOSED_MANUAL"}


@dataclass(frozen=True)
class LifecycleResult:
    family_id: str
    family_state: str
    legs_total: int
    legs_open: int
    legs_closed: int
    realized_pnl: str
    floating_pnl: str
    exposure_at_sl: str


def _d(value) -> Decimal:
    if value is None:
        return Decimal("0")
    return Decimal(str(value))


def _leg_realized_pnl(*, side: str, entry, exit_price, lots) -> Decimal:
    entry_d = _d(entry)
    exit_d = _d(exit_price)
    lots_d = _d(lots)

    if entry_d <= 0 or exit_d <= 0 or lots_d <= 0:
        return Decimal("0")

    if side.lower() == "buy":
        return (exit_d - entry_d) * lots_d

    return (entry_d - exit_d) * lots_d


def _leg_floating_pnl(*, side: str, entry, current_price, lots) -> Decimal:
    return _leg_realized_pnl(side=side, entry=entry, exit_price=current_price, lots=lots)


def _leg_exposure_at_sl(*, entry, sl, lots) -> Decimal:
    entry_d = _d(entry)
    sl_d = _d(sl)
    lots_d = _d(lots)

    if entry_d <= 0 or sl_d <= 0 or lots_d <= 0:
        return Decimal("0")

    return abs(entry_d - sl_d) * lots_d


def recompute_family_lifecycle(*, family_id: str, mark_price: str | None = None) -> LifecycleResult:
    with SessionLocal() as db:
        rows = db.execute(
            text(
                """
                SELECT
                  tl.leg_id::text AS leg_id,
                  tl.state AS leg_state,
                  tl.entry_price,
                  tl.requested_entry,
                  tl.sl_price,
                  tl.tp_price,
                  tl.lots,
                  tf.side,
                  COALESCE(et.actual_fill_price, tl.requested_entry, tl.entry_price) AS fill_price,
                  et.status AS ticket_status
                FROM trade_legs tl
                JOIN trade_families tf ON tf.family_id = tl.family_id
                LEFT JOIN execution_tickets et ON et.leg_id = tl.leg_id
                WHERE tl.family_id = CAST(:family_id AS uuid)
                ORDER BY tl.leg_index
                """
            ),
            {"family_id": family_id},
        ).mappings().all()

        if not rows:
            raise RuntimeError(f"No legs found for family_id={family_id}")

        legs_total = len(rows)
        legs_closed = 0
        legs_open = 0
        realized = Decimal("0")
        floating = Decimal("0")
        exposure = Decimal("0")

        for r in rows:
            state = str(r["leg_state"])
            side = str(r["side"])
            entry = r["fill_price"] or r["requested_entry"] or r["entry_price"]
            lots = r["lots"]

            if state in CLOSED_STATES:
                legs_closed += 1

                if state == "TP_HIT":
                    exit_price = r["tp_price"]
                elif state == "SL_HIT":
                    exit_price = r["sl_price"]
                else:
                    # Manual/unknown close: use last known fill as neutral unless later replaced
                    exit_price = entry

                realized += _leg_realized_pnl(
                    side=side,
                    entry=entry,
                    exit_price=exit_price,
                    lots=lots,
                )
                continue

            legs_open += 1

            current_price = mark_price or entry
            floating += _leg_floating_pnl(
                side=side,
                entry=entry,
                current_price=current_price,
                lots=lots,
            )
            exposure += _leg_exposure_at_sl(
                entry=entry,
                sl=r["sl_price"],
                lots=lots,
            )

        if legs_closed == legs_total:
            family_state = "CLOSED"
        elif legs_closed > 0:
            family_state = "PARTIALLY_CLOSED"
        else:
            family_state = "OPEN"

        db.execute(
            text(
                """
                UPDATE trade_families
                SET state = :state,
                    meta = (meta::jsonb || jsonb_build_object(
                        'lifecycle',
                        jsonb_build_object(
                            'realized_pnl', CAST(:realized_pnl AS numeric),
                            'floating_pnl', CAST(:floating_pnl AS numeric),
                            'exposure_at_sl', CAST(:exposure_at_sl AS numeric),
                            'legs_total', CAST(:legs_total AS int),
                            'legs_open', CAST(:legs_open AS int),
                            'legs_closed', CAST(:legs_closed AS int)
                        )
                    ))::json,
                    updated_at = now()
                WHERE family_id = CAST(:family_id AS uuid)
                """
            ),
            {
                "family_id": family_id,
                "state": family_state,
                "realized_pnl": str(realized),
                "floating_pnl": str(floating),
                "exposure_at_sl": str(exposure),
                "legs_total": legs_total,
                "legs_open": legs_open,
                "legs_closed": legs_closed,
            },
        )
        db.commit()

    return LifecycleResult(
        family_id=family_id,
        family_state=family_state,
        legs_total=legs_total,
        legs_open=legs_open,
        legs_closed=legs_closed,
        realized_pnl=str(realized),
        floating_pnl=str(floating),
        exposure_at_sl=str(exposure),
    )
