from __future__ import annotations

import re
from typing import Optional, Tuple

ALIASES = {
    "gold": "XAUUSD",
    "xau": "XAUUSD",
    "xauusd": "XAUUSD",
    "dj30": "DJ30",
    "us30": "DJ30",
    "dow": "DJ30",
    "nas100": "NAS100",
    "nq": "NAS100",
    "nas": "NAS100",
    "spx": "SPX500",
    "sp500": "SPX500",
    "btc": "BTCUSD",
    "btcusdt": "BTCUSD",
    "btc/usdt": "BTCUSD",
    "ethusdt": "ETHUSD",
    "eth": "ETHUSD",
}

SYMBOL_TOKEN_RE = re.compile(r"(?i)\b([a-z0-9]{2,12}(?:/[a-z0-9]{2,12})?)\b")

RESERVED_TOKENS = {
    "buy",
    "sell",
    "long",
    "short",
    "entry",
    "entries",
    "sl",
    "tp",
    "target",
    "targets",
    "stop",
    "limit",
    "update",
    "close",
}

FX_CODES = {"USD", "EUR", "GBP", "JPY", "AUD", "NZD", "CAD", "CHF"}


def resolve_symbol(raw: str) -> Tuple[Optional[str], Optional[str]]:
    if not raw:
        return None, None
    raw_norm = raw.strip().lower()
    canon = ALIASES.get(raw_norm)
    if canon:
        return canon, raw.strip()
    # If it looks like a broker-style symbol already
    if raw.strip().upper() in {"XAUUSD", "DJ30", "NAS100", "BTCUSD", "ETHUSD", "SPX500"}:
        return raw.strip().upper(), raw.strip()
    # Skip command-like tokens
    if raw_norm in RESERVED_TOKENS:
        return None, raw.strip()
    # Fallback: preserve only plausible symbol-like tokens
    # - contains digits (e.g. NAS100), or
    # - looks like valid 6-letter forex pair (e.g. EURUSD)
    token = raw.strip()
    if re.fullmatch(r"[A-Za-z0-9]{3,12}", token):
        has_digit = bool(re.search(r"\d", token))
        upper = token.upper()
        is_fx_pair = bool(re.fullmatch(r"[A-Za-z]{6}", token)) and upper[:3] in FX_CODES and upper[3:] in FX_CODES
        if has_digit or is_fx_pair:
            return raw.strip().upper(), raw.strip()
    return None, raw.strip()


def find_first_symbol(text: str) -> Tuple[Optional[str], Optional[str]]:
    for m in SYMBOL_TOKEN_RE.finditer(text):
        token = m.group(1)
        canon, raw = resolve_symbol(token)
        if canon:
            return canon, raw
    return None, None
