from pathlib import Path

import yaml

from app.risk.lot_sizing import LotSizingInput, resolve_lot_sizing


def test_small_account_brokers_include_bullwaves_not_vtmarkets():
    from app.services.small_account_lot_sizing import SUPPORTED_SMALL_BROKERS

    assert "vantage" in SUPPORTED_SMALL_BROKERS
    assert "startrader" in SUPPORTED_SMALL_BROKERS
    assert "bullwaves" in SUPPORTED_SMALL_BROKERS
    assert "vtmarkets" not in SUPPORTED_SMALL_BROKERS


def test_bullwaves_500_gbp_gets_004_lots():
    result = resolve_lot_sizing(
        LotSizingInput(
            provider="fredtrading",
            account_type="bullwaves",
            account_size=500,
            account_currency="GBP",
            modifiers=[],
            tp_count=4,
        )
    )

    assert result.total_lots == "0.04"
    assert result.per_leg_lots == ["0.01", "0.01", "0.01", "0.01"]


def test_broker_profile_files_exist():
    for broker in ["vantage", "startrader", "bullwaves"]:
        p = Path(f"config/broker_profiles/{broker}.yaml")
        assert p.exists()
        data = yaml.safe_load(p.read_text())
        assert data["broker"] == broker
        assert data["small_account_lot_profile"]["total_lots"] == 0.04


def test_symbol_maps_have_small_brokers():
    data = yaml.safe_load(Path("config/symbol_maps.yaml").read_text())
    brokers = data["brokers"]

    for broker in ["vantage", "startrader", "bullwaves"]:
        assert broker in brokers
        assert "mt5" in brokers[broker]
        assert "XAUUSD" in brokers[broker]["mt5"]
