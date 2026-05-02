from __future__ import annotations

from dataclasses import dataclass
from decimal import Decimal
from pathlib import Path

import yaml


DEFAULT_FX_RATES_PATH = Path("config/fx_rates.yaml")


@dataclass(frozen=True)
class FxNormalizationResult:
    amount: str
    currency: str
    base_currency: str
    normalized_amount: str
    rate_to_base: str


def _d(value) -> Decimal:
    return Decimal(str(value))


def load_fx_config(path: Path | None = None) -> dict:
    path = path or DEFAULT_FX_RATES_PATH
    with path.open("r", encoding="utf-8") as f:
        return yaml.safe_load(f) or {}


def normalize_to_base(
    *,
    amount: str | int | Decimal,
    currency: str,
    path: Path | None = None,
) -> FxNormalizationResult:
    cfg = load_fx_config(path)
    base_currency = str(cfg.get("base_currency", "GBP")).upper()
    currency = currency.upper()

    rates = cfg.get("rates_to_base") or {}
    if currency not in rates:
        raise ValueError(f"Unsupported account currency: {currency}")

    rate = _d(rates[currency])
    normalized = _d(amount) * rate

    return FxNormalizationResult(
        amount=str(amount),
        currency=currency,
        base_currency=base_currency,
        normalized_amount=str(normalized.quantize(Decimal("0.01"))),
        rate_to_base=str(rate),
    )
