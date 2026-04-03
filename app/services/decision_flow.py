from __future__ import annotations

from dataclasses import dataclass
from typing import Optional

from app.decision.engine import decide_signal
from app.decision.models import DecisionAction, DecisionContext, DecisionResult
from app.parsing.models import ParsedSignal
from app.services.approvals import ApprovalCard, create_approval_if_missing


@dataclass(frozen=True)
class DecisionFlowResult:
    decision: DecisionResult
    approval_card: Optional[ApprovalCard] = None
    persisted_state: Optional[str] = None


def process_decision_flow(
    *,
    source_msg_pk: str,
    provider_code: str,
    parsed: ParsedSignal,
    duplicate: bool = False,
    risk_checks_pass: bool = True,
) -> DecisionFlowResult:
    """
    Deterministic flow orchestration for Milestone 4.

    No execution logic here.
    No broker calls here.
    Only decides:
      - state
      - whether approval is needed
      - whether to create an approval record/card
    """
    ctx = DecisionContext(
        provider_code=provider_code,
        parsed=parsed,
        duplicate=duplicate,
        risk_checks_pass=risk_checks_pass,
    )
    decision = decide_signal(ctx)

    if decision.action == DecisionAction.IGNORE_DUPLICATE:
        return DecisionFlowResult(decision=decision, approval_card=None, persisted_state=None)

    if decision.action == DecisionAction.REQUIRE_APPROVAL:
        card = create_approval_if_missing(
            source_msg_pk=source_msg_pk,
            provider_code=provider_code,
            parsed=parsed,
            decision=decision,
        )
        return DecisionFlowResult(
            decision=decision,
            approval_card=card,
            persisted_state=decision.state.value if decision.state else None,
        )

    if decision.action in {
        DecisionAction.CREATE_CANDIDATE,
        DecisionAction.PENDING_UPDATE,
        DecisionAction.AUTO_PLACE,
        DecisionAction.NO_ACTION,
    }:
        return DecisionFlowResult(
            decision=decision,
            approval_card=None,
            persisted_state=decision.state.value if decision.state else None,
        )

    return DecisionFlowResult(
        decision=decision,
        approval_card=None,
        persisted_state=decision.state.value if decision.state else None,
    )
