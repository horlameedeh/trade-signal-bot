from __future__ import annotations

from dataclasses import dataclass
from decimal import Decimal

from sqlalchemy import text

from app.db.session import SessionLocal
from app.risk.prop_rules import PropRiskInput, PropRiskResult, evaluate_prop_risk


@dataclass(frozen=True)
class ExposureSnapshot:
    family_id: str
    broker: str
    platform: str
    starting_balance: str
    account_equity: str
    new_trade_risk_at_sl: str
    current_open_risk: str


def _d(value) -> Decimal:
    if value is None:
        return Decimal("0")
    return Decimal(str(value))


def _risk_at_sl(*, entry_price, sl_price, lots) -> Decimal:
    """
    Conservative generic risk proxy.

    This is intentionally broker-agnostic for Milestone 11.
    Later we can replace this with broker/symbol tick-value-aware calculation.
    """
    entry = _d(entry_price)
    sl = _d(sl_price)
    lot = _d(lots)

    if entry <= 0 or sl <= 0 or lot <= 0:
        return Decimal("0")

    return abs(entry - sl) * lot


def compute_family_risk_at_sl(*, family_id: str) -> Decimal:
    with SessionLocal() as db:
        rows = db.execute(
            text(
                """
                SELECT entry_price, requested_entry, sl_price, lots
                FROM trade_legs
                WHERE family_id = CAST(:family_id AS uuid)
                  AND state = 'OPEN'
                ORDER BY leg_index
                """
            ),
            {"family_id": family_id},
        ).mappings().all()

    total = Decimal("0")
    for r in rows:
        entry = r["requested_entry"] or r["entry_price"]
        total += _risk_at_sl(
            entry_price=entry,
            sl_price=r["sl_price"],
            lots=r["lots"],
        )

    return total


def compute_current_open_risk_for_account(*, account_id: str, exclude_family_id: str | None = None) -> Decimal:
    with SessionLocal() as db:
        rows = db.execute(
            text(
                """
                SELECT tl.entry_price, tl.requested_entry, tl.sl_price, tl.lots
                FROM trade_legs tl
                JOIN trade_families tf ON tf.family_id = tl.family_id
                WHERE tf.account_id = CAST(:account_id AS uuid)
                  AND tf.state IN ('OPEN', 'PENDING_UPDATE')
                  AND tl.state = 'OPEN'
                  AND (CAST(:exclude_family_id AS text) IS NULL OR tf.family_id <> CAST(:exclude_family_id AS uuid))
                """
            ),
            {"account_id": account_id, "exclude_family_id": exclude_family_id},
        ).mappings().all()

    total = Decimal("0")
    for r in rows:
        entry = r["requested_entry"] or r["entry_price"]
        total += _risk_at_sl(
            entry_price=entry,
            sl_price=r["sl_price"],
            lots=r["lots"],
        )

    return total


def build_exposure_snapshot(*, family_id: str) -> ExposureSnapshot:
    with SessionLocal() as db:
        row = db.execute(
            text(
                """
                SELECT
                  tf.family_id::text AS family_id,
                  tf.account_id::text AS account_id,
                  ba.broker,
                  ba.platform,
                  COALESCE(ba.equity_start, 0)::text AS starting_balance,
                  COALESCE(ba.equity_current, ba.equity_start, 0)::text AS account_equity
                FROM trade_families tf
                JOIN broker_accounts ba ON ba.account_id = tf.account_id
                WHERE tf.family_id = CAST(:family_id AS uuid)
                LIMIT 1
                """
            ),
            {"family_id": family_id},
        ).mappings().first()

    if not row:
        raise RuntimeError(f"trade_family not found: {family_id}")

    new_risk = compute_family_risk_at_sl(family_id=family_id)
    current_risk = compute_current_open_risk_for_account(
        account_id=row["account_id"],
        exclude_family_id=family_id,
    )

    return ExposureSnapshot(
        family_id=row["family_id"],
        broker=row["broker"],
        platform=row["platform"],
        starting_balance=row["starting_balance"],
        account_equity=row["account_equity"],
        new_trade_risk_at_sl=str(new_risk),
        current_open_risk=str(current_risk),
    )


def evaluate_family_prop_risk(
    *,
    family_id: str,
    daily_realized_pnl: str = "0",
    total_realized_pnl: str = "0",
) -> PropRiskResult:
    snap = build_exposure_snapshot(family_id=family_id)

    return evaluate_prop_risk(
        PropRiskInput(
            broker=snap.broker,
            account_equity=snap.account_equity,
            starting_balance=snap.starting_balance,
            daily_realized_pnl=daily_realized_pnl,
            total_realized_pnl=total_realized_pnl,
            current_open_risk=snap.current_open_risk,
            new_trade_risk_at_sl=snap.new_trade_risk_at_sl,
        )
    )
