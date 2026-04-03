from pathlib import Path

import pytest

from app.parsing.models import MessageType, Side
from app.parsing.parser import parse_message


def _load_cases(path: str) -> dict[str, str]:
    text = Path(path).read_text(encoding="utf-8")
    cases: dict[str, str] = {}
    current_name = None
    current_lines = []
    for ln in text.splitlines():
        if ln.startswith("=== CASE:"):
            if current_name is not None:
                cases[current_name] = "\n".join(current_lines).strip()
            current_name = ln.replace("=== CASE:", "").strip()
            current_lines = []
        else:
            current_lines.append(ln)
    if current_name is not None:
        cases[current_name] = "\n".join(current_lines).strip()
    return cases


FRED = _load_cases("tests/fixtures/fredtrading_samples.txt")
BC = _load_cases("tests/fixtures/billionaire_club_samples.txt")
MUB = _load_cases("tests/fixtures/mubeen_samples.txt")


def test_fred_half_risk_dj30():
    sig = parse_message("fredtrading", FRED["fred_half_risk_dj30"])
    assert sig.message_type == MessageType.NEW_TRADE
    assert sig.symbol == "DJ30"
    assert sig.side == Side.BUY
    assert "HALF_RISK" in sig.flags
    assert sig.tps == ["48750", "48800", "48920"]


def test_fred_unofficial_gold():
    sig = parse_message("fredtrading", FRED["fred_unofficial_gold"])
    assert sig.message_type == MessageType.NEW_TRADE
    assert sig.symbol == "XAUUSD"
    assert sig.unofficial is True
    assert sig.confidence < 100


def test_fred_scalp_runner():
    sig = parse_message("fredtrading", FRED["fred_scalp_runner"])
    assert sig.message_type == MessageType.NEW_TRADE
    assert sig.symbol == "BTCUSD"
    assert "SCALP" in sig.flags
    assert "HALF_SIZE" in sig.flags
    assert sig.tps[-1] == "runner"


def test_fred_stub_gold():
    sig = parse_message("fredtrading", FRED["fred_stub_gold"])
    assert sig.message_type == MessageType.NEW_TRADE
    assert sig.symbol == "XAUUSD"
    assert sig.side == Side.BUY
    assert sig.entry == "29"
    assert sig.confidence <= 60


def test_fred_update_sl_to_entry():
    sig = parse_message("fredtrading", FRED["fred_update_sl_to_entry"])
    assert sig.message_type == MessageType.UPDATE
    assert sig.update is not None
    assert sig.update.move_sl_to_entry is True


def test_fred_move_tp4s():
    sig = parse_message("fredtrading", FRED["fred_move_tp4s"])
    assert sig.message_type == MessageType.UPDATE
    assert sig.update is not None
    assert sig.update.move_tp_to_price.get(4) == "4527"


def test_bc_sell_xau():
    sig = parse_message("billionaire_club", BC["bc_sell_xau"])
    assert sig.message_type == MessageType.NEW_TRADE
    assert sig.symbol == "XAUUSD"
    assert sig.side == Side.SELL
    assert sig.tps == ["4947", "4944", "4938"]
    assert sig.confidence == 100


def test_bc_update_be_without_symbol_is_update():
    sig = parse_message("billionaire_club", BC["bc_update_be"])
    assert sig.message_type == MessageType.UPDATE
    assert sig.update is not None
    assert sig.update.move_sl_to_be is True
    assert sig.update.symbol is None


def test_mubeen_tp4_split():
    sig = parse_message("mubeen", MUB["mub_limit_tp4_split"])
    assert sig.message_type == MessageType.NEW_TRADE
    assert sig.symbol == "XAUUSD"
    assert sig.order_type.value == "limit"
    assert sig.tps == ["4950", "4953", "4956", "4970", "4985"]


def test_mubeen_stub_multiline():
    sig = parse_message("mubeen", MUB["mub_stub_gold_multiline"])
    assert sig.message_type == MessageType.NEW_TRADE
    assert sig.symbol == "XAUUSD"
    assert sig.entry == "4821"


def test_mubeen_high_risk():
    sig = parse_message("mubeen", MUB["mub_high_risk"])
    assert "HIGH_RISK" in sig.flags
    assert sig.message_type == MessageType.NEW_TRADE


def test_mubeen_reenter_tiny():
    sig = parse_message("mubeen", MUB["mub_reenter_tiny"])
    assert "REENTER" in sig.flags
    assert "TINY_RISK" in sig.flags


def test_mubeen_unlabeled_tps():
    sig = parse_message("mubeen", MUB["mub_unlabeled_tps"])
    assert sig.message_type == MessageType.NEW_TRADE
    assert sig.symbol == "DJ30"
    assert sig.tps == ["49540", "49570", "49600", "49650"]


def test_mubeen_checked_sl_and_tp_cleanup():
    sig = parse_message("mubeen", MUB["mub_scalp_checked_sl"])
    assert sig.message_type == MessageType.NEW_TRADE
    assert sig.sl == "4469"
    assert sig.tps == ["4460", "4457", "4454", "4450"]


def test_mubeen_btcusdt_commas():
    sig = parse_message("mubeen", MUB["mub_btcusdt_commas"])
    assert sig.message_type == MessageType.NEW_TRADE
    assert sig.symbol == "BTCUSD"
    assert sig.tps[-1] == "100,700"
