from app.risk.lot_sizing import LotSizingInput, resolve_lot_sizing


def test_fred_live_1k_normal():
    result = resolve_lot_sizing(
        LotSizingInput(
            provider="fredtrading",
            account_type="live",
            account_size=1000,
            modifiers=[],
            tp_count=4,
        )
    )
    assert result.total_lots == "0.08"
    assert result.per_leg_lots == ["0.02", "0.02", "0.02", "0.02"]


def test_fred_ftmo_10k_normal():
    result = resolve_lot_sizing(
        LotSizingInput(
            provider="fredtrading",
            account_type="ftmo",
            account_size=10000,
            modifiers=[],
            tp_count=4,
        )
    )
    assert result.total_lots == "0.20"
    assert result.per_leg_lots == ["0.05", "0.05", "0.05", "0.05"]


def test_fred_ftmo_20k_half_risk():
    result = resolve_lot_sizing(
        LotSizingInput(
            provider="fredtrading",
            account_type="ftmo",
            account_size=20000,
            modifiers=["HALF_RISK"],
            tp_count=4,
        )
    )
    assert result.total_lots == "0.20"
    assert result.per_leg_lots == ["0.05", "0.05", "0.05", "0.05"]


def test_fred_ftmo_35k_half_of_half():
    result = resolve_lot_sizing(
        LotSizingInput(
            provider="fredtrading",
            account_type="ftmo",
            account_size=35000,
            modifiers=["HALF_OF_HALF"],
            tp_count=4,
        )
    )
    assert result.total_lots == "0.15"
    assert result.modifier_multiplier == "0.25"


def test_fred_ftmo_100k_normal():
    result = resolve_lot_sizing(
        LotSizingInput(
            provider="fredtrading",
            account_type="ftmo",
            account_size=100000,
            modifiers=[],
            tp_count=4,
        )
    )
    assert result.total_lots == "1.20"
    assert result.per_leg_lots == ["0.30", "0.30", "0.30", "0.30"]


def test_fred_ftmo_100k_special_trying_something_out():
    result = resolve_lot_sizing(
        LotSizingInput(
            provider="fredtrading",
            account_type="ftmo",
            account_size=100000,
            modifiers=[],
            tp_count=2,
            special_rule="trying_something_out",
        )
    )
    assert result.style_used == "special_trying_something_out"
    assert result.total_lots == "0.80"
    assert result.per_leg_lots == ["0.40", "0.40"]


def test_fred_ftmo_100k_swing():
    result = resolve_lot_sizing(
        LotSizingInput(
            provider="fredtrading",
            account_type="ftmo",
            account_size=100000,
            modifiers=[],
            tp_count=4,
            is_swing=True,
        )
    )
    assert result.style_used == "swing"
    assert result.total_lots == "0.16"
    assert result.per_leg_lots == ["0.04", "0.04", "0.04", "0.04"]


def test_high_risk_does_not_scale_up():
    normal = resolve_lot_sizing(
        LotSizingInput(
            provider="mubeen",
            account_type="fundednext",
            account_size=10000,
            modifiers=[],
            tp_count=4,
        )
    )
    high = resolve_lot_sizing(
        LotSizingInput(
            provider="mubeen",
            account_type="fundednext",
            account_size=10000,
            modifiers=["HIGH_RISK"],
            tp_count=4,
        )
    )
    assert high.total_lots == normal.total_lots


def test_billio_mirrors_fred_table_for_now():
    result = resolve_lot_sizing(
        LotSizingInput(
            provider="billionaire_club",
            account_type="traderscale",
            account_size=20000,
            modifiers=[],
            tp_count=4,
        )
    )
    assert result.total_lots == "0.40"
    assert result.per_leg_lots == ["0.10", "0.10", "0.10", "0.10"]


def test_four_tp_signal_splits_into_four_legs():
    result = resolve_lot_sizing(
        LotSizingInput(
            provider="mubeen",
            account_type="fundednext",
            account_size=20000,
            modifiers=[],
            tp_count=4,
        )
    )
    assert result.total_lots == "0.40"
    assert result.per_leg_lots == ["0.10", "0.10", "0.10", "0.10"]
