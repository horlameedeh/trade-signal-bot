from app.services.small_account_lot_sizing import resolve_small_account_lot_sizing


def test_500_gbp_vantage_gets_004_total_lots():
    result = resolve_small_account_lot_sizing(
        broker="vantage",
        account_size="500",
        account_currency="GBP",
        tp_count=4,
    )

    assert result.applies is True
    assert result.total_lot == "0.04"
    assert result.leg_lots == ["0.01", "0.01", "0.01", "0.01"]


def test_350_gbp_startrader_gets_004_total_lots():
    result = resolve_small_account_lot_sizing(
        broker="startrader",
        account_size="350",
        account_currency="GBP",
        tp_count=4,
    )

    assert result.applies is True
    assert result.total_lot == "0.04"
    assert result.leg_lots == ["0.01", "0.01", "0.01", "0.01"]


def test_500_gbp_vtmarkets_gets_004_total_lots():
    result = resolve_small_account_lot_sizing(
        broker="vtmarkets",
        account_size="500",
        account_currency="GBP",
        tp_count=4,
    )

    assert result.applies is True
    assert result.total_lot == "0.04"


def test_non_small_account_does_not_apply():
    result = resolve_small_account_lot_sizing(
        broker="vantage",
        account_size="10000",
        account_currency="GBP",
        tp_count=4,
    )

    assert result.applies is False
    assert result.reason == "small_account_profile_not_applicable"


def test_unsupported_broker_does_not_apply():
    result = resolve_small_account_lot_sizing(
        broker="ftmo",
        account_size="500",
        account_currency="GBP",
        tp_count=4,
    )

    assert result.applies is False


def test_currency_normalized_equivalent_applies():
    # USD rate in config/fx_rates.yaml is 0.80, so 625 USD = 500 GBP normalized.
    result = resolve_small_account_lot_sizing(
        broker="vantage",
        account_size="625",
        account_currency="USD",
        tp_count=4,
    )

    assert result.applies is True
    assert result.normalized_account_size == "500.00"
    assert result.total_lot == "0.04"
