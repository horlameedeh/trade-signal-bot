from __future__ import annotations

from dataclasses import dataclass, field
from enum import Enum
from typing import Any, Optional


class MessageType(str, Enum):
    NEW_TRADE = "NEW_TRADE"
    UPDATE = "UPDATE"          # choose UPDATE consistently
    INFO = "INFO"
    UNKNOWN = "UNKNOWN"


class Side(str, Enum):
    BUY = "BUY"
    SELL = "SELL"


class OrderType(str, Enum):
    MARKET = "market"
    LIMIT = "limit"
    STOP = "stop"


@dataclass
class UpdateIntent:
    """Parsed intent for UPDATE messages. Symbol may be None."""
    symbol: Optional[str] = None
    raw_symbol: Optional[str] = None

    move_sl_to_entry: bool = False
    move_sl_to_be: bool = False  # "breakeven"
    move_sl_to_price: Optional[str] = None  # exact as stated

    # Move TP to price, or "TP4 4970 4985" => deterministic extra targets
    move_tp_to_price: dict[int, str] = field(default_factory=dict)  # tp_index -> price string
    add_tps: list[str] = field(default_factory=list)  # additional target prices in order

    close_all: bool = False
    close_partial: Optional[str] = None  # e.g. "50%" or "half"

    # Free-form taggable
    notes: list[str] = field(default_factory=list)


@dataclass(frozen=True)
class ParsedSignal:
    provider_code: str
    message_type: MessageType

    # Common
    raw_text: str
    clean_text: str

    # NEW_TRADE fields
    symbol: Optional[str] = None
    raw_symbol: Optional[str] = None
    side: Optional[Side] = None
    order_type: Optional[OrderType] = None
    entry: Optional[str] = None          # keep exact numeric integrity as string
    sl: Optional[str] = None
    tps: list[str] = field(default_factory=list)  # ordered list, exact strings

    # UPDATE fields
    update: Optional[UpdateIntent] = None

    # Flags/modifiers
    flags: list[str] = field(default_factory=list)
    unofficial: bool = False

    # Global management default (always ON)
    be_at_tp1: bool = True

    # Deterministic confidence 0-100
    confidence: int = 0

    # Any extra structured extraction
    meta: dict[str, Any] = field(default_factory=dict)
