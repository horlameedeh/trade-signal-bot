from __future__ import annotations

from dataclasses import dataclass, field
from enum import Enum
from typing import Optional

from app.parsing.models import MessageType, ParsedSignal


class DecisionAction(str, Enum):
    AUTO_PLACE = "AUTO_PLACE"
    CREATE_CANDIDATE = "CREATE_CANDIDATE"
    PENDING_UPDATE = "PENDING_UPDATE"
    REQUIRE_APPROVAL = "REQUIRE_APPROVAL"
    IGNORE_DUPLICATE = "IGNORE_DUPLICATE"
    NO_ACTION = "NO_ACTION"


class TradeFamilyState(str, Enum):
    CANDIDATE = "CANDIDATE"
    PENDING_UPDATE = "PENDING_UPDATE"
    PENDING_APPROVAL = "PENDING_APPROVAL"
    OPEN = "OPEN"
    CLOSED = "CLOSED"
    REJECTED = "REJECTED"
    ERROR = "ERROR"


@dataclass(frozen=True)
class DecisionContext:
    provider_code: str
    parsed: ParsedSignal
    duplicate: bool = False
    risk_checks_pass: bool = True


@dataclass(frozen=True)
class DecisionResult:
    action: DecisionAction
    state: Optional[TradeFamilyState]
    reason: str
    requires_approval: bool = False
    emergency_sl_required: bool = False
    be_at_tp1: bool = True
    tags: list[str] = field(default_factory=list)
