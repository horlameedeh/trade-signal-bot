from __future__ import annotations

import re
from typing import Optional

from app.parsing.confidence import score_confidence
from app.parsing.models import MessageType, OrderType, ParsedSignal, Side, UpdateIntent
from app.parsing.normalize import clean_text, extract_numbers, first_number, preserve_tp_order
from app.parsing.symbols import find_first_symbol, resolve_symbol


BUY_RE = re.compile(r"(?i)\b(buy|long)\b")
SELL_RE = re.compile(r"(?i)\b(sell|short)\b")

LIMIT_RE = re.compile(r"(?i)\b(limit)\b")
STOP_RE = re.compile(r"(?i)\b(stop)\b")
NOW_RE = re.compile(r"(?i)\b(now)\b")

SL_RE = re.compile(r"(?i)\b(sl|stoploss|stop loss)\b")
TP_RE = re.compile(r"(?i)\b(tp\d*|t/p|take profit|targets?)\b")

UNOFFICIAL_RE = re.compile(r"(?i)\b(not official|personal trade|i do not recommend|your choice|personally i won[’']?t be entering|it'?s there for those who want)\b")
SCALP_RE = re.compile(r"(?i)\b(scalp|scalping)\b")
SWING_RE = re.compile(r"(?i)\b(swing)\b")
REENTER_RE = re.compile(r"(?i)\b(re[- ]?enter|reentry)\b")

RISK_HALF_RE = re.compile(r"(?i)\b(half risk|half size)\b")
RISK_HALF_OF_HALF_RE = re.compile(r"(?i)\b(half of half)\b")
RISK_HIGH_RE = re.compile(r"(?i)\b(high risk)\b")
RISK_TINY_RE = re.compile(r"(?i)\b(tiny risk|small risk|low risk)\b")
RISK_NORMAL_RE = re.compile(r"(?i)\b(normal risk)\b")

# UPDATE patterns
BE_RE = re.compile(r"(?i)\b(break even|breakeven|be)\b")
MOVE_SL_TO_ENTRY_RE = re.compile(r"(?i)\b(sl to entry|move sl to entry|sl entry at tp1)\b")
MOVE_SL_TO_BE_RE = re.compile(r"(?i)\b(move stop loss to break even|move sl to be|sl to be|sl breakeven|sl to breakeven)\b")
CLOSE_ALL_RE = re.compile(r"(?i)\b(close all|close everything|exit all)\b")
CLOSE_PARTIAL_RE = re.compile(r"(?i)(close partial|close\s*(\d{1,3})%|close half|partial close)")
MOVE_TP_TO_RE = re.compile(r"(?i)\b(tp\s*(\d{1,2})s?\s*(?:to|@)\s*([-0-9.,]+))\b")
MOVE_TPS_TO_RE = re.compile(r"(?i)\b(move tp(\d{1,2})s?\s*to\s*([-0-9.,]+))\b")
MOVE_SL_PRICE_RE = re.compile(r"(?i)\b(sl\s*(?:to|@)\s*([-0-9.,]+))\b")


def _detect_side(text: str) -> Optional[Side]:
    if BUY_RE.search(text):
        return Side.BUY
    if SELL_RE.search(text):
        return Side.SELL
    return None


def _detect_order_type(text: str) -> OrderType:
    if LIMIT_RE.search(text):
        return OrderType.LIMIT
    if STOP_RE.search(text):
        return OrderType.STOP
    return OrderType.MARKET


def _extract_flags(text: str) -> tuple[list[str], bool]:
    flags: list[str] = []
    unofficial = bool(UNOFFICIAL_RE.search(text))

    if RISK_HALF_OF_HALF_RE.search(text):
        flags.append("HALF_OF_HALF")
    elif RISK_HALF_RE.search(text):
        # Keep HALF_SIZE distinction if phrase appears
        if re.search(r"(?i)\bhalf size\b", text):
            flags.append("HALF_SIZE")
        else:
            flags.append("HALF_RISK")
    elif RISK_HIGH_RE.search(text):
        flags.append("HIGH_RISK")
    elif RISK_TINY_RE.search(text):
        flags.append("TINY_RISK")
    elif RISK_NORMAL_RE.search(text):
        flags.append("NORMAL_RISK")

    if REENTER_RE.search(text):
        flags.append("REENTER")
    if SCALP_RE.search(text):
        flags.append("SCALP")
    if SWING_RE.search(text):
        flags.append("SWING")
    if unofficial:
        flags.append("UNOFFICIAL")

    return flags, unofficial


def _parse_sl(text: str) -> Optional[str]:
    for ln in text.split("\n"):
        if SL_RE.search(ln):
            nums = extract_numbers(ln)
            if nums:
                return nums[0]
    return None


def _parse_entry(text: str) -> Optional[str]:
    # Entry / Enter / Entering
    for pat in [
        r"(?i)\b(entry|enter|entering|entries)\b[:\-\s]*([^\n]+)",
        r"(?i)\b(entry|enter|entering|entries)\b[:\-\s]*\n([^\n]+)",
    ]:
        m = re.search(pat, text)
        if m:
            n = first_number(m.group(2))
            if n:
                return n

    # Fallback for "buy gold now 29" or multiline stub where side+symbol present
    nums = extract_numbers(text)
    return nums[0] if nums else None


def _parse_tps(text: str) -> list[str]:
    lines = [ln.strip() for ln in text.split("\n") if ln.strip()]
    tps: list[str] = []

    # 1) labeled TP/Target lines
    for ln in lines:
        if TP_RE.search(ln):
            ln_wo_parens = re.sub(r"\([^)]*\)", "", ln)
            nums = extract_numbers(ln_wo_parens)
            if not nums:
                if "runner" in ln.lower():
                    tps.append("runner")
                continue

            # Remove numbered TP indices from extracted numbers, e.g.
            # "TP1 2050 TP2 2075" -> ["2050", "2075"]
            idx_nums = re.findall(r"(?i)(?:tp|target)\s*([1-9]\d?)", ln_wo_parens)
            if idx_nums:
                idx_multiset = list(idx_nums)
                filtered: list[str] = []
                for n in nums:
                    if idx_multiset and n == idx_multiset[0]:
                        idx_multiset.pop(0)
                    else:
                        filtered.append(n)
                nums = filtered

            if nums:
                tps.extend(nums)
            if "runner" in ln.lower():
                tps.append("runner")

    # 2) unlabeled TP block:
    #    TPs
    #    49540
    #    49570
    #    ...
    for i, ln in enumerate(lines):
        if re.fullmatch(r"(?i)tps?|targets?", ln):
            block: list[str] = []
            for nxt in lines[i + 1:]:
                # stop at first obvious non-number/non-runner line
                if not extract_numbers(nxt) and "runner" not in nxt.lower():
                    break
                nums = extract_numbers(nxt)
                if nums:
                    block.extend(nums)
                elif "runner" in nxt.lower():
                    block.append("runner")
            if block:
                return preserve_tp_order(block)

    if tps:
        return preserve_tp_order(tps)

    # 3) inline "TP’s 24860, 24780, 24140"
    m = re.search(r"(?i)\b(tp'?s?|targets?)\b[:\-\s]*(.+)$", text.replace("\n", " "))
    if m:
        nums = extract_numbers(m.group(2))
        if nums:
            return preserve_tp_order(nums)

    return []


def _looks_like_update(text: str) -> bool:
    return any(
        r.search(text)
        for r in [
            MOVE_SL_TO_ENTRY_RE,
            MOVE_SL_TO_BE_RE,
            BE_RE,
            MOVE_TP_TO_RE,
            MOVE_TPS_TO_RE,
            MOVE_SL_PRICE_RE,
            CLOSE_ALL_RE,
            CLOSE_PARTIAL_RE,
        ]
    )


def _parse_update(provider_code: str, raw_text: str, clean: str) -> ParsedSignal:
    sym, raw_sym = find_first_symbol(clean)
    upd = UpdateIntent(symbol=sym, raw_symbol=raw_sym)

    if MOVE_SL_TO_ENTRY_RE.search(clean):
        upd.move_sl_to_entry = True
    if MOVE_SL_TO_BE_RE.search(clean) or (BE_RE.search(clean) and "stop loss" in clean.lower()):
        upd.move_sl_to_be = True

    msl = MOVE_SL_PRICE_RE.search(clean)
    if msl:
        price = first_number(msl.group(1)) or msl.group(1).strip()
        upd.move_sl_to_price = price

    for m in MOVE_TP_TO_RE.finditer(clean):
        tp_idx = int(m.group(2))
        price = first_number(m.group(3)) or m.group(3).strip()
        upd.move_tp_to_price[tp_idx] = price

    for m in MOVE_TPS_TO_RE.finditer(clean):
        tp_idx = int(m.group(2))
        price = first_number(m.group(3)) or m.group(3).strip()
        upd.move_tp_to_price[tp_idx] = price

    if CLOSE_ALL_RE.search(clean):
        upd.close_all = True

    mcp = CLOSE_PARTIAL_RE.search(clean)
    if mcp:
        pct = mcp.group(2)
        upd.close_partial = f"{pct}%" if pct else "partial"

    # If update mentions TPs and includes numbers but no explicit move_tp_to_price, preserve as add_tps
    if TP_RE.search(clean):
        nums = _parse_tps(clean)
        if nums and not upd.move_tp_to_price:
            upd.add_tps = nums

    flags, unofficial = _extract_flags(clean)

    sig = ParsedSignal(
        provider_code=provider_code,
        message_type=MessageType.UPDATE,
        raw_text=raw_text,
        clean_text=clean,
        update=upd,
        flags=flags,
        unofficial=unofficial,
        be_at_tp1=True,
        confidence=0,
        meta={},
    )
    return sig.__class__(**{**sig.__dict__, "confidence": score_confidence(sig)})


def parse_message(provider_code: str, text: str) -> ParsedSignal:
    raw_text = text or ""
    clean = clean_text(raw_text)

    flags, unofficial = _extract_flags(clean)

    if _looks_like_update(clean):
        return _parse_update(provider_code, raw_text, clean)

    side = _detect_side(clean)
    sym, raw_sym = find_first_symbol(clean)

    # Handle "Buy gold now" / "Sell gold" style where symbol token may be a common noun
    if not sym:
        m = re.search(r"(?i)\b(gold|silver|dj30|nas100|btcusdt|btcusd|eurusd|eurjpy|usdcad|gbpnzd|gbpcad|usdjpy|xauusd)\b", clean)
        if m:
            sym, raw_sym = resolve_symbol(m.group(1))

    order_type = _detect_order_type(clean)
    entry = _parse_entry(clean)
    sl = _parse_sl(clean)
    tps = _parse_tps(clean)

    if side and sym:
        sig = ParsedSignal(
            provider_code=provider_code,
            message_type=MessageType.NEW_TRADE,
            raw_text=raw_text,
            clean_text=clean,
            symbol=sym,
            raw_symbol=raw_sym,
            side=side,
            order_type=order_type,
            entry=entry,
            sl=sl,
            tps=tps,
            flags=flags,
            unofficial=unofficial,
            be_at_tp1=True,
            confidence=0,
            meta={},
        )
        return sig.__class__(**{**sig.__dict__, "confidence": score_confidence(sig)})

    msg_type = MessageType.INFO if unofficial or TP_RE.search(clean) or SL_RE.search(clean) else MessageType.UNKNOWN
    sig = ParsedSignal(
        provider_code=provider_code,
        message_type=msg_type,
        raw_text=raw_text,
        clean_text=clean,
        flags=flags,
        unofficial=unofficial,
        be_at_tp1=True,
        confidence=0,
        meta={},
    )
    return sig.__class__(**{**sig.__dict__, "confidence": score_confidence(sig)})
