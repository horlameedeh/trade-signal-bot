from pathlib import Path

import pytest

from app.services.fx_rates import normalize_to_base


def test_normalize_gbp_to_gbp():
    result = normalize_to_base(amount="500", currency="GBP")

    assert result.currency == "GBP"
    assert result.base_currency == "GBP"
    assert result.normalized_amount == "500.00"


def test_normalize_supported_currencies():
    for currency in ["USD", "EUR", "CZK", "GBP", "AUD", "CAD", "CHF"]:
        result = normalize_to_base(amount="500", currency=currency)
        assert result.currency == currency
        assert result.normalized_amount is not None


def test_unsupported_currency_raises():
    with pytest.raises(ValueError):
        normalize_to_base(amount="500", currency="JPY")


def test_custom_rates_file(tmp_path: Path):
    p = tmp_path / "fx_rates.yaml"
    p.write_text(
        """
base_currency: GBP
rates_to_base:
  USD: 0.5
""",
        encoding="utf-8",
    )

    result = normalize_to_base(amount="100", currency="USD", path=p)

    assert result.normalized_amount == "50.00"
