from __future__ import annotations

from dataclasses import dataclass
from decimal import Decimal
from pathlib import Path
from typing import Literal

import yaml
from sqlalchemy import text

from app.db.session import SessionLocal


DEFAULT_GLOBAL_SAFETY_PATH = Path("config/global_safety.yaml")


GlobalSafetyDecision = Literal["allow", "require_approval", "block"]


@dataclass(frozen=True)
class GlobalSafetyResult:
    decision: GlobalSafetyDecision
    reasons: list[str]
    trades_today: int
    open_trades: int
    symbol: str | None
    symbol_exposure: str
    global_realized_loss: str


def _d(value) -> Decimal:
    if value is None:
        return Decimal("0")
    return Decimal(str(value))


def load_global_safety_config(path: Path = DEFAULT_GLOBAL_SAFETY_PATH) -> dict:
    with path.open("r", encoding="utf-8") as f:
        return yaml.safe_load(f) or {}


def _family_symbol(*, family_id: str) -> str | None:
    with SessionLocal() as db:
        return db.execute(
            text(
                """
                SELECT symbol_canonical
                FROM trade_families
                WHERE family_id = CAST(:family_id AS uuid)
                LIMIT 1
                """
            ),
            {"family_id": family_id},
        ).scalar()


def _count_trades_today() -> int:
    with SessionLocal() as db:
        return int(
            db.execute(
                text(
                    """
                    SELECT COUNT(*)
                    FROM trade_families
                    WHERE created_at::date = now()::date
                    """
                )
            ).scalar()
            or 0
        )


def _count_open_trades() -> int:
    with SessionLocal() as db:
        return int(
            db.execute(
                text(
                    """
                    SELECT COUNT(*)
                    FROM trade_families
                    WHERE state IN ('OPEN', 'PARTIALLY_CLOSED', 'PENDING_UPDATE')
                    """
                )
            ).scalar()
            or 0
        )


def _symbol_open_exposure(symbol: str) -> Decimal:
    with SessionLocal() as db:
        rows = db.execute(
            text(
                """
                SELECT
                  COALESCE(tl.requested_entry, tl.entry_price) AS entry_price,
                  tl.sl_price,
                  tl.lots
                FROM trade_legs tl
                JOIN trade_families tf ON tf.family_id = tl.family_id
                WHERE tf.symbol_canonical = :symbol
                  AND tf.state IN ('OPEN', 'PARTIALLY_CLOSED', 'PENDING_UPDATE')
                  AND tl.state = 'OPEN'
                """
            ),
            {"symbol": symbol},
        ).mappings().all()

    total = Decimal("0")
    for r in rows:
        entry = _d(r["entry_price"])
        sl = _d(r["sl_price"])
        lots = _d(r["lots"])

        if entry > 0 and sl > 0 and lots > 0:
            total += abs(entry - sl) * lots

    return total


def _global_realized_loss() -> Decimal:
    """
    Uses lifecycle metadata where available.
    Loss is positive number.
    """
    with SessionLocal() as db:
        rows = db.execute(
            text(
                """
                SELECT meta->'lifecycle'->>'realized_pnl' AS realized_pnl
                FROM trade_families
                WHERE meta::jsonb ? 'lifecycle'
                """
            )
        ).mappings().all()

    total_loss = Decimal("0")
    for r in rows:
        pnl = _d(r["realized_pnl"])
        if pnl < 0:
            total_loss += abs(pnl)

    return total_loss


def _family_execution_cap_context(*, family_id: str) -> dict | None:
    with SessionLocal() as db:
        row = db.execute(
            text(
                """
                SELECT
                  ba.broker::text AS broker,
                  ba.kind::text AS account_type,
                  COALESCE(ba.equity_start, ba.equity_current, 0) AS account_size,
                  COALESCE(SUM(tl.lots), 0) AS total_lots
                FROM trade_families tf
                JOIN broker_accounts ba ON ba.account_id = tf.account_id
                JOIN trade_legs tl ON tl.family_id = tf.family_id
                WHERE tf.family_id = CAST(:family_id AS uuid)
                GROUP BY ba.broker, ba.kind, ba.equity_start, ba.equity_current
                LIMIT 1
                """
            ),
            {"family_id": family_id},
        ).mappings().first()

    return dict(row) if row else None


def _max_total_lots_for_context(
    *, cfg: dict, broker: str, account_type: str, account_size: int
) -> Decimal | None:
    caps = cfg.get("execution_caps") or {}

    account_caps = caps.get("accounts") or {}
    account_key = f"{broker}:{account_type}:{account_size}"

    if account_key in account_caps:
        value = account_caps[account_key].get("max_total_lots")
        return _d(value) if value is not None else None

    broker_caps = caps.get("brokers") or {}
    if broker in broker_caps:
        value = broker_caps[broker].get("max_total_lots")
        return _d(value) if value is not None else None

    default_value = caps.get("default_max_total_lots")
    return _d(default_value) if default_value is not None else None


def evaluate_global_safety(
    *,
    family_id: str | None = None,
    symbol: str | None = None,
    path: Path | None = None,
) -> GlobalSafetyResult:
    if path is None:
        path = DEFAULT_GLOBAL_SAFETY_PATH
    cfg = load_global_safety_config(path)

    if not cfg.get("enabled", True):
        return GlobalSafetyResult(
            decision="allow",
            reasons=["global_safety_disabled"],
            trades_today=0,
            open_trades=0,
            symbol=symbol,
            symbol_exposure="0",
            global_realized_loss="0",
        )

    kill = cfg.get("kill_switch") or {}
    if kill.get("enabled"):
        return GlobalSafetyResult(
            decision="block",
            reasons=[f"kill_switch_enabled:{kill.get('reason') or 'no_reason'}"],
            trades_today=0,
            open_trades=0,
            symbol=symbol,
            symbol_exposure="0",
            global_realized_loss="0",
        )

    if symbol is None and family_id:
        symbol = _family_symbol(family_id=family_id)

    limits = cfg.get("limits") or {}
    threshold = _d(cfg.get("near_limit_threshold_pct", 80)) / Decimal("100")

    trades_today = _count_trades_today()
    open_trades = _count_open_trades()
    symbol_exposure = _symbol_open_exposure(symbol) if symbol else Decimal("0")
    global_loss = _global_realized_loss()

    reasons: list[str] = []
    decision: GlobalSafetyDecision = "allow"

    max_trades_per_day = limits.get("max_trades_per_day")
    if max_trades_per_day is not None:
        max_trades = int(max_trades_per_day)
        if trades_today >= max_trades:
            decision = "block"
            reasons.append("max_trades_per_day_breached")
        elif trades_today >= int(Decimal(max_trades) * threshold):
            decision = "require_approval"
            reasons.append("near_max_trades_per_day")

    max_open_trades = limits.get("max_open_trades")
    if max_open_trades is not None:
        max_open = int(max_open_trades)
        if open_trades >= max_open:
            decision = "block"
            reasons.append("max_open_trades_breached")
        elif decision != "block" and open_trades >= int(Decimal(max_open) * threshold):
            decision = "require_approval"
            reasons.append("near_max_open_trades")

    max_exposure_by_symbol = limits.get("max_exposure_per_symbol") or {}
    if symbol and symbol in max_exposure_by_symbol:
        max_exposure = _d(max_exposure_by_symbol[symbol])
        if symbol_exposure >= max_exposure:
            decision = "block"
            reasons.append("max_exposure_per_symbol_breached")
        elif decision != "block" and symbol_exposure >= max_exposure * threshold:
            decision = "require_approval"
            reasons.append("near_max_exposure_per_symbol")

    global_loss_cutoff = limits.get("global_loss_cutoff")
    if global_loss_cutoff is not None:
        cutoff = _d(global_loss_cutoff)
        if global_loss >= cutoff:
            decision = "block"
            reasons.append("global_loss_cutoff_breached")
        elif decision != "block" and global_loss >= cutoff * threshold:
            decision = "require_approval"
            reasons.append("near_global_loss_cutoff")

    if family_id:
        cap_ctx = _family_execution_cap_context(family_id=family_id)
        if cap_ctx:
            broker = str(cap_ctx["broker"])
            account_type = str(cap_ctx["account_type"])
            account_size = int(_d(cap_ctx["account_size"]))
            total_lots = _d(cap_ctx["total_lots"])

            max_total_lots = _max_total_lots_for_context(
                cfg=cfg,
                broker=broker,
                account_type=account_type,
                account_size=account_size,
            )

            if max_total_lots is not None and total_lots > max_total_lots:
                decision = "block"
                reasons.append(
                    f"max_total_lots_exceeded:{broker}:{total_lots}>{max_total_lots}"
                )

    if not reasons:
        reasons.append("within_global_safety_limits")

    return GlobalSafetyResult(
        decision=decision,
        reasons=reasons,
        trades_today=trades_today,
        open_trades=open_trades,
        symbol=symbol,
        symbol_exposure=str(symbol_exposure),
        global_realized_loss=str(global_loss),
    )
