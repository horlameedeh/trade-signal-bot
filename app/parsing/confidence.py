from __future__ import annotations

from app.parsing.models import ParsedSignal, MessageType


def score_confidence(sig: ParsedSignal) -> int:
    # Deterministic rule-based score 0–100
    if sig.message_type == MessageType.NEW_TRADE:
        score = 100

        # missing core fields reduce
        if not sig.symbol or not sig.side:
            score -= 50

        # entry optional for market; but missing entry + missing SL/TP reduces
        if not sig.sl:
            score -= 20
        if not sig.tps:
            score -= 20

        # stub/minimal detection
        # (symbol+side but no SL/TP)
        if sig.symbol and sig.side and (not sig.sl and not sig.tps):
            score = min(score, 60)

        # disclaimer/unofficial
        if sig.unofficial:
            score -= 15

        # clamp
        return max(0, min(100, score))

    if sig.message_type == MessageType.UPDATE:
        # Update messages have lower typical confidence, but still deterministic
        score = 80
        if sig.unofficial:
            score -= 10
        # Symbol missing
        if not sig.update or not sig.update.symbol:
            score -= 20
        return max(0, min(100, score))

    if sig.message_type == MessageType.INFO:
        return 30 if sig.unofficial else 40

    return 10
