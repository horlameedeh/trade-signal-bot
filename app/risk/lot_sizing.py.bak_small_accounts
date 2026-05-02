from __future__ import annotations

from dataclasses import dataclass
from decimal import Decimal, ROUND_HALF_UP


@dataclass(frozen=True)
class LotSizingInput:
    provider: str
    account_type: str
    account_size: int
    modifiers: list[str]
    tp_count: int
    special_rule: str | None = None
    is_swing: bool = False


@dataclass(frozen=True)
class LotSizingResult:
    total_lots: str
    per_leg_lots: list[str]
    modifier_multiplier: str
    style_used: str


_BASE_TABLE: dict[tuple[str, str, int], Decimal] = {
    ("fredtrading", "live", 1000): Decimal("0.08"),
    ("fredtrading", "ftmo", 10000): Decimal("0.20"),
    ("fredtrading", "ftmo", 20000): Decimal("0.40"),
    ("fredtrading", "ftmo", 35000): Decimal("0.60"),
    ("fredtrading", "ftmo", 100000): Decimal("1.20"),
    ("billionaire_club", "traderscale", 20000): Decimal("0.40"),
    ("mubeen", "fundednext", 10000): Decimal("0.20"),
    ("mubeen", "fundednext", 20000): Decimal("0.40"),
}


def _fmt_2dp(value: Decimal) -> str:
    return str(value.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP))


def _modifier_multiplier(modifiers: list[str]) -> Decimal:
    modifier_set = {m.upper() for m in modifiers}
    if "HALF_OF_HALF" in modifier_set:
        return Decimal("0.25")
    if "HALF_RISK" in modifier_set:
        return Decimal("0.50")
    return Decimal("1")


def _resolve_base_total(inp: LotSizingInput) -> Decimal:
    key = (inp.provider, inp.account_type, int(inp.account_size))
    if key in _BASE_TABLE:
        return _BASE_TABLE[key]

    provider_account = [
        lots
        for (provider, account_type, _size), lots in _BASE_TABLE.items()
        if provider == inp.provider and account_type == inp.account_type
    ]
    if provider_account:
        return provider_account[-1]

    return Decimal("0.20")


def resolve_lot_sizing(inp: LotSizingInput) -> LotSizingResult:
    base_total = _resolve_base_total(inp)
    style_used = "normal"

    if inp.special_rule == "trying_something_out" and inp.provider == "fredtrading" and inp.tp_count == 2:
        total = Decimal("0.80")
        per_leg = ["0.40", "0.40"]
        return LotSizingResult(
            total_lots=_fmt_2dp(total),
            per_leg_lots=per_leg,
            modifier_multiplier="1",
            style_used="special_trying_something_out",
        )

    if inp.is_swing:
        total = (base_total * Decimal("0.1333333333")).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)
        style_used = "swing"
    else:
        multiplier = _modifier_multiplier(inp.modifiers)
        total = (base_total * multiplier).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)

    leg_count = max(1, int(inp.tp_count))
    per_leg_value = (total / Decimal(leg_count)).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)
    per_leg = [_fmt_2dp(per_leg_value) for _ in range(leg_count)]

    return LotSizingResult(
        total_lots=_fmt_2dp(total),
        per_leg_lots=per_leg,
        modifier_multiplier=_fmt_2dp(_modifier_multiplier(inp.modifiers)).rstrip("0").rstrip("."),
        style_used=style_used,
    )
