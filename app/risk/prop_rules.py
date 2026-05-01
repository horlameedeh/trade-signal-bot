from __future__ import annotations

from dataclasses import dataclass
from decimal import Decimal
from pathlib import Path
from typing import Literal

import yaml


DEFAULT_PROP_RULES_PATH = Path("config/prop_risk_rules.yaml")


RiskDecision = Literal["allow", "require_approval", "block"]


@dataclass(frozen=True)
class PropRiskInput:
    broker: str
    account_equity: str
    starting_balance: str
    daily_realized_pnl: str
    total_realized_pnl: str
    current_open_risk: str
    new_trade_risk_at_sl: str


@dataclass(frozen=True)
class PropRiskResult:
    decision: RiskDecision
    broker: str
    daily_loss_limit: str
    total_loss_limit: str
    projected_daily_loss: str
    projected_total_loss: str
    current_open_risk: str
    new_trade_risk_at_sl: str
    reasons: list[str]


def _d(value: str | int | float | Decimal) -> Decimal:
    return Decimal(str(value))


def _load_rules(path: Path = DEFAULT_PROP_RULES_PATH) -> dict:
    with path.open("r", encoding="utf-8") as f:
        return yaml.safe_load(f)


def _loss_amount(pnl: Decimal) -> Decimal:
    return abs(pnl) if pnl < 0 else Decimal("0")


def evaluate_prop_risk(
    inp: PropRiskInput,
    *,
    path: Path = DEFAULT_PROP_RULES_PATH,
) -> PropRiskResult:
    rules = _load_rules(path)
    broker = inp.broker.lower()

    profile = rules.get("profiles", {}).get(broker)
    if not profile:
        return PropRiskResult(
            decision="block",
            broker=broker,
            daily_loss_limit="0",
            total_loss_limit="0",
            projected_daily_loss="0",
            projected_total_loss="0",
            current_open_risk=str(inp.current_open_risk),
            new_trade_risk_at_sl=str(inp.new_trade_risk_at_sl),
            reasons=[f"missing_prop_risk_profile:{broker}"],
        )

    starting_balance = _d(inp.starting_balance)
    daily_realized_pnl = _d(inp.daily_realized_pnl)
    total_realized_pnl = _d(inp.total_realized_pnl)
    current_open_risk = _d(inp.current_open_risk)
    new_trade_risk = _d(inp.new_trade_risk_at_sl)

    daily_limit = starting_balance * (_d(profile["max_daily_loss_pct"]) / Decimal("100"))
    total_limit = starting_balance * (_d(profile["max_total_loss_pct"]) / Decimal("100"))
    near_threshold = _d(profile.get("near_limit_threshold_pct", 80)) / Decimal("100")

    projected_daily_loss = _loss_amount(daily_realized_pnl) + current_open_risk + new_trade_risk
    projected_total_loss = _loss_amount(total_realized_pnl) + current_open_risk + new_trade_risk

    reasons: list[str] = []
    decision: RiskDecision = "allow"

    if projected_daily_loss >= daily_limit:
        decision = "block"
        reasons.append("daily_loss_limit_breached")

    if projected_total_loss >= total_limit:
        decision = "block"
        reasons.append("total_loss_limit_breached")

    if decision != "block":
        if projected_daily_loss >= daily_limit * near_threshold:
            decision = "require_approval"
            reasons.append("near_daily_loss_limit")

        if projected_total_loss >= total_limit * near_threshold:
            decision = "require_approval"
            reasons.append("near_total_loss_limit")

    if not reasons:
        reasons.append("within_prop_risk_limits")

    return PropRiskResult(
        decision=decision,
        broker=broker,
        daily_loss_limit=str(daily_limit),
        total_loss_limit=str(total_limit),
        projected_daily_loss=str(projected_daily_loss),
        projected_total_loss=str(projected_total_loss),
        current_open_risk=str(current_open_risk),
        new_trade_risk_at_sl=str(new_trade_risk),
        reasons=reasons,
    )
