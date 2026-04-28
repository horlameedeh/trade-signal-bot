from decimal import Decimal

from app.execution.entry_policy import EntryPolicyInput, build_entry_plan


def test_buy_limit_uses_descending_micro_ladder():
    result = build_entry_plan(
        EntryPolicyInput(
            symbol="XAUUSD",
            side="buy",
            order_type="limit",
            entry_price="4662",
            legs_count=3,
        )
    )
    assert result.requested_entries == ["4662", "4661", "4660"]
    assert result.tp_preserved is True


def test_sell_limit_uses_ascending_micro_ladder():
    result = build_entry_plan(
        EntryPolicyInput(
            symbol="XAUUSD",
            side="sell",
            order_type="limit",
            entry_price="4662",
            legs_count=3,
        )
    )
    assert result.requested_entries == ["4662", "4663", "4664"]


def test_buy_stop_uses_ascending_micro_ladder():
    result = build_entry_plan(
        EntryPolicyInput(
            symbol="EURUSD",
            side="buy",
            order_type="stop",
            entry_price="1.18220",
            legs_count=3,
        )
    )
    assert result.requested_entries == ["1.18220", "1.18221", "1.18222"]


def test_sell_stop_uses_descending_micro_ladder():
    result = build_entry_plan(
        EntryPolicyInput(
            symbol="EURUSD",
            side="sell",
            order_type="stop",
            entry_price="1.18220",
            legs_count=3,
        )
    )
    assert result.requested_entries == ["1.18220", "1.18219", "1.18218"]


def test_market_order_keeps_same_requested_entry_and_sequential_delays():
    result = build_entry_plan(
        EntryPolicyInput(
            symbol="BTCUSD",
            side="buy",
            order_type="market",
            entry_price="91800",
            legs_count=4,
        )
    )
    assert result.requested_entries == ["91800", "91800", "91800", "91800"]
    assert result.market_delays_ms == [0, 250, 500, 750]


def test_indices_use_index_class():
    result = build_entry_plan(
        EntryPolicyInput(
            symbol="DJ30",
            side="buy",
            order_type="limit",
            entry_price="49000",
            legs_count=2,
        )
    )
    assert result.instrument_class == "indices"
    assert result.requested_entries == ["49000", "48995"]


def test_tp_values_are_preserved_by_policy_contract():
    result = build_entry_plan(
        EntryPolicyInput(
            symbol="XAUUSD",
            side="buy",
            order_type="limit",
            entry_price="4662",
            legs_count=2,
        )
    )
    assert result.tp_preserved is True
