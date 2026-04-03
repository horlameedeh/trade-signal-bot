import pytest

from app.parsing.models import MessageType, Side
from app.parsing.parser import parse_message


@pytest.mark.parametrize(
    "provider,text,expect_symbol,expect_side",
    [
        ("fredtrading", "BUY GOLD now 2025\\nSL 2012\\nTP1 2050 TP2 2075", "XAUUSD", Side.BUY),
        ("billionaire_club", "Sell nas100 @ 18050\\nStop loss 18120\\nTargets: 17980, 17910, 17840", "NAS100", Side.SELL),
        ("mubeen", "Long btcusdt 52000\\nSL 51000\\nTP 53000 54000", "BTCUSD", Side.BUY),
    ],
)
def test_new_trade_parses_core_fields(provider, text, expect_symbol, expect_side):
    sig = parse_message(provider, text)
    assert sig.message_type == MessageType.NEW_TRADE
    assert sig.symbol == expect_symbol
    assert sig.side == expect_side
    assert sig.confidence >= 80


def test_stub_minimal_message_is_new_trade_low_confidence():
    sig = parse_message("fredtrading", "Buy gold now 29")
    assert sig.message_type == MessageType.NEW_TRADE
    assert sig.symbol == "XAUUSD"
    assert sig.side == Side.BUY
    assert sig.confidence <= 60


def test_disclaimer_not_discarded_unofficial_flag_confidence_reduced():
    sig = parse_message("mubeen", "BUY GOLD now\\n(not official)\\nSL 2010\\nTP 2030")
    assert sig.message_type == MessageType.NEW_TRADE
    assert sig.unofficial is True
    assert sig.confidence < 100


def test_tp4_two_numbers_splits_deterministically():
    sig = parse_message("billionaire_club", "SELL DJ30\\nSL 40100\\nTP4 39950 39880")
    assert sig.message_type == MessageType.NEW_TRADE
    # our tp parser just extends with both numbers in order
    assert sig.tps == ["39950", "39880"]


def test_update_move_sl_to_be_parses_update():
    sig = parse_message("fredtrading", "GOLD update: move SL to BE ✅")
    assert sig.message_type == MessageType.UPDATE
    assert sig.update is not None
    assert sig.update.move_sl_to_be is True
    assert sig.confidence >= 50


def test_update_close_partial_parses():
    sig = parse_message("billionaire_club", "NAS100 close 50% now")
    assert sig.message_type == MessageType.UPDATE
    assert sig.update is not None
    assert sig.update.close_partial == "50%"


def test_update_tp_move_parses():
    sig = parse_message("mubeen", "BTC update: TP1 to 53000")
    assert sig.message_type == MessageType.UPDATE
    assert sig.update is not None
    assert sig.update.move_tp_to_price.get(1) == "53000"
