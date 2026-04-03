from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from enum import Enum
from typing import Optional


class TimeoutAction(str, Enum):
    NONE = "NONE"
    REQUIRE_APPROVAL = "REQUIRE_APPROVAL"
    ALERT_AND_APPROVAL = "ALERT_AND_APPROVAL"
    ESCALATE = "ESCALATE"


@dataclass(frozen=True)
class TimeoutPolicy:
    candidate_minutes: int = 10
    pending_update_minutes: int = 30
    escalate_minutes: int = 120


@dataclass(frozen=True)
class TimeoutEvaluation:
    action: TimeoutAction
    reason: str
    age_minutes: int


def _minutes_since(created_at: datetime, now: Optional[datetime] = None) -> int:
    if now is None:
        now = datetime.now(timezone.utc)

    if created_at.tzinfo is None:
        created_at = created_at.replace(tzinfo=timezone.utc)

    delta = now - created_at
    return max(0, int(delta.total_seconds() // 60))


def evaluate_timeout(
    *,
    state: str,
    created_at: datetime,
    now: Optional[datetime] = None,
    policy: Optional[TimeoutPolicy] = None,
) -> TimeoutEvaluation:
    """
    States:
      - CANDIDATE
      - PENDING_UPDATE
      - PENDING_APPROVAL
      - others => no timeout action

    Rules:
      - CANDIDATE >= 10 min => REQUIRE_APPROVAL
      - PENDING_UPDATE >= 30 min => ALERT_AND_APPROVAL
      - any unresolved state >= 120 min => ESCALATE
    """
    policy = policy or TimeoutPolicy()
    age_minutes = _minutes_since(created_at, now=now)

    unresolved_states = {"CANDIDATE", "PENDING_UPDATE", "PENDING_APPROVAL"}

    if state in unresolved_states and age_minutes >= policy.escalate_minutes:
        return TimeoutEvaluation(
            action=TimeoutAction.ESCALATE,
            reason="timeout_escalation",
            age_minutes=age_minutes,
        )

    if state == "CANDIDATE" and age_minutes >= policy.candidate_minutes:
        return TimeoutEvaluation(
            action=TimeoutAction.REQUIRE_APPROVAL,
            reason="candidate_timeout_requires_approval",
            age_minutes=age_minutes,
        )

    if state == "PENDING_UPDATE" and age_minutes >= policy.pending_update_minutes:
        return TimeoutEvaluation(
            action=TimeoutAction.ALERT_AND_APPROVAL,
            reason="pending_update_timeout_alert_and_approval",
            age_minutes=age_minutes,
        )

    return TimeoutEvaluation(
        action=TimeoutAction.NONE,
        reason="no_timeout_action",
        age_minutes=age_minutes,
    )
