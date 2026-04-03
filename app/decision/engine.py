from __future__ import annotations

from app.decision.models import (
    DecisionAction,
    DecisionContext,
    DecisionResult,
    TradeFamilyState,
)
from app.parsing.models import MessageType


def _is_stub_trade(ctx: DecisionContext) -> bool:
    p = ctx.parsed
    if p.message_type != MessageType.NEW_TRADE:
        return False
    # stub allowed: symbol + side + market-ish intent, but missing SL or TPs
    if not p.symbol or not p.side:
        return False
    return not p.sl or len(p.tps) == 0


def _is_complete_trade(ctx: DecisionContext) -> bool:
    p = ctx.parsed
    if p.message_type != MessageType.NEW_TRADE:
        return False
    return bool(
        p.symbol
        and p.side
        and (p.entry is not None or p.order_type is not None)
        and p.sl
        and len(p.tps) >= 1
    )


def decide_signal(ctx: DecisionContext) -> DecisionResult:
    p = ctx.parsed
    flags = set(p.flags or [])

    if ctx.duplicate:
        return DecisionResult(
            action=DecisionAction.IGNORE_DUPLICATE,
            state=None,
            reason="duplicate_signal",
            requires_approval=False,
        )

    if not ctx.risk_checks_pass:
        return DecisionResult(
            action=DecisionAction.REQUIRE_APPROVAL,
            state=TradeFamilyState.PENDING_APPROVAL,
            reason="risk_checks_failed",
            requires_approval=True,
        )

    if p.message_type == MessageType.UPDATE:
        return DecisionResult(
            action=DecisionAction.NO_ACTION,
            state=None,
            reason="update_message_handled_elsewhere",
            requires_approval=False,
        )

    if p.message_type not in {MessageType.NEW_TRADE}:
        return DecisionResult(
            action=DecisionAction.NO_ACTION,
            state=None,
            reason=f"message_type_{p.message_type.value.lower()}",
            requires_approval=False,
        )

    # Highest-priority approval rules
    if p.provider_code == "mubeen" and "HIGH_RISK" in flags:
        return DecisionResult(
            action=DecisionAction.REQUIRE_APPROVAL,
            state=TradeFamilyState.PENDING_APPROVAL,
            reason="mubeen_high_risk_requires_approval",
            requires_approval=True,
            tags=["HIGH_RISK"],
        )

    if "REENTER" in flags:
        return DecisionResult(
            action=DecisionAction.REQUIRE_APPROVAL,
            state=TradeFamilyState.PENDING_APPROVAL,
            reason="reenter_requires_approval",
            requires_approval=True,
            tags=["REENTER"],
        )

    if p.unofficial:
        return DecisionResult(
            action=DecisionAction.CREATE_CANDIDATE,
            state=TradeFamilyState.CANDIDATE,
            reason="unofficial_or_disclaimer_trade_wait_for_update",
            requires_approval=False,
            tags=["UNOFFICIAL"],
        )

    if _is_stub_trade(ctx):
        return DecisionResult(
            action=DecisionAction.PENDING_UPDATE,
            state=TradeFamilyState.PENDING_UPDATE,
            reason="stub_trade_auto_place_with_emergency_sl",
            emergency_sl_required=True,
            requires_approval=False,
        )

    if _is_complete_trade(ctx):
        return DecisionResult(
            action=DecisionAction.AUTO_PLACE,
            state=TradeFamilyState.OPEN,
            reason="complete_trade_auto_place",
            requires_approval=False,
        )

    # incomplete / ambiguous non-stub
    return DecisionResult(
        action=DecisionAction.REQUIRE_APPROVAL,
        state=TradeFamilyState.PENDING_APPROVAL,
        reason="ambiguous_or_incomplete_trade_requires_approval",
        requires_approval=True,
    )
