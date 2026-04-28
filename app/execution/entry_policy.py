from __future__ import annotations

from dataclasses import dataclass
from decimal import Decimal
from pathlib import Path
from typing import Optional

import yaml


DEFAULT_EXECUTION_POLICY_PATH = Path("config/execution_semantics.yaml")


@dataclass(frozen=True)
class EntryPolicyInput:
    symbol: str
    side: str
    order_type: str
    entry_price: str
    legs_count: int


@dataclass(frozen=True)
class LegExecutionPlan:
    leg_index: int
    requested_entry: str
    tp_price: Optional[str] = None


@dataclass(frozen=True)
class MarketExecutionPlan:
    leg_index: int
    requested_entry: str
    delay_ms: int


@dataclass(frozen=True)
class EntryPolicyResult:
    symbol: str
    instrument_class: str
    order_type: str
    requested_entries: list[str]
    market_delays_ms: list[int]
    tp_preserved: bool


def _load_policy(path: Path = DEFAULT_EXECUTION_POLICY_PATH) -> dict:
    with path.open("r", encoding="utf-8") as f:
        return yaml.safe_load(f)


def _to_decimal(value: str) -> Decimal:
    return Decimal(str(value))


def _instrument_class(symbol: str, policy: dict) -> str:
    overrides = policy.get("symbol_class_overrides", {})
    sym = symbol.upper()
    if sym in overrides:
        return str(overrides[sym])
    return "fx"


def _point_size(symbol: str) -> Decimal:
    sym = symbol.upper()
    if sym in {"XAUUSD", "XAGUSD", "DJ30", "NAS100", "BTCUSD"}:
        return Decimal("1")
    if sym.endswith("JPY"):
        return Decimal("0.001")
    return Decimal("0.00001")


def build_entry_plan(
    inp: EntryPolicyInput,
    *,
    path: Path = DEFAULT_EXECUTION_POLICY_PATH,
) -> EntryPolicyResult:
    if inp.legs_count <= 0:
        raise ValueError("legs_count must be > 0")

    policy = _load_policy(path)
    iclass = _instrument_class(inp.symbol, policy)
    class_cfg = policy["instrument_classes"][iclass]

    point = _point_size(inp.symbol)
    entry = _to_decimal(inp.entry_price)

    jitter_min = int(class_cfg["entry_jitter_points"]["min"])
    jitter_max = int(class_cfg["entry_jitter_points"]["max"])
    market_delay_min = int(class_cfg["market_delay_ms"]["min"])

    requested_entries: list[str] = []
    market_delays: list[int] = []

    order_type = inp.order_type.lower()
    side = inp.side.lower()

    if order_type in {"limit", "stop"}:
        # deterministic micro-ladder using min jitter
        delta = Decimal(jitter_min) * point

        for idx in range(inp.legs_count):
            if order_type == "limit":
                if side == "buy":
                    price = entry - (delta * idx)
                else:
                    price = entry + (delta * idx)
            else:  # stop
                if side == "buy":
                    price = entry + (delta * idx)
                else:
                    price = entry - (delta * idx)

            requested_entries.append(str(price))
            market_delays.append(0)

    elif order_type == "market":
        for idx in range(inp.legs_count):
            requested_entries.append(str(entry))
            market_delays.append(market_delay_min * idx)
    else:
        raise ValueError(f"Unsupported order_type: {inp.order_type}")

    return EntryPolicyResult(
        symbol=inp.symbol,
        instrument_class=iclass,
        order_type=order_type,
        requested_entries=requested_entries,
        market_delays_ms=market_delays,
        tp_preserved=True,
    )
