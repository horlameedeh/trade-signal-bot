from app.services.symbol_aliases import resolve_broker_symbol


def test_same_canonical_symbol_resolves_differently_across_brokers():
    ftmo = resolve_broker_symbol(
        canonical_symbol="DJ30",
        broker="ftmo",
        platform="mt5",
    )
    vantage = resolve_broker_symbol(
        canonical_symbol="DJ30",
        broker="vantage",
        platform="mt5",
    )

    assert ftmo.found is True
    assert vantage.found is True
    assert ftmo.resolved_symbol != vantage.resolved_symbol


def test_crypto_mapping_can_differ_from_provider_raw():
    result = resolve_broker_symbol(
        canonical_symbol="BTCUSD",
        broker="fundednext",
        platform="mt5",
    )
    assert result.found is True
    assert result.resolved_symbol == "BTCUSD"


def test_unknown_symbol_blocks_trading():
    result = resolve_broker_symbol(
        canonical_symbol="UNKNOWNXYZ",
        broker="ftmo",
        platform="mt5",
    )
    assert result.found is False
    assert result.blocked is True
    assert result.reason == "missing_symbol_mapping"


def test_unknown_broker_blocks_trading():
    result = resolve_broker_symbol(
        canonical_symbol="XAUUSD",
        broker="madeupbroker",
        platform="mt5",
    )
    assert result.found is False
    assert result.blocked is True
    assert result.reason == "unknown_broker_profile"


def test_unknown_platform_blocks_trading():
    result = resolve_broker_symbol(
        canonical_symbol="XAUUSD",
        broker="ftmo",
        platform="ctrader",
    )
    assert result.found is False
    assert result.blocked is True
    assert result.reason == "unknown_platform_profile"
