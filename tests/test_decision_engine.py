from app.decision.engine import decide_signal
from app.decision.models import DecisionAction, DecisionContext, TradeFamilyState
from app.parsing.parser import parse_message


def test_complete_trade_auto_places():
    parsed = parse_message("fredtrading", "BUY GOLD now\nSL 2010\nTP 2030 2040")
    result = decide_signal(DecisionContext(provider_code="fredtrading", parsed=parsed))
    assert result.action == DecisionAction.AUTO_PLACE
    assert result.state == TradeFamilyState.OPEN


def test_stub_trade_becomes_pending_update():
    parsed = parse_message("fredtrading", "Buy gold now 29")
    result = decide_signal(DecisionContext(provider_code="fredtrading", parsed=parsed))
    assert result.action == DecisionAction.PENDING_UPDATE
    assert result.state == TradeFamilyState.PENDING_UPDATE
    assert result.emergency_sl_required is True


def test_unofficial_trade_becomes_candidate():
    parsed = parse_message("fredtrading", "BUY GOLD now\n(not official)\nSL 2010\nTP 2030")
    result = decide_signal(DecisionContext(provider_code="fredtrading", parsed=parsed))
    assert result.action == DecisionAction.CREATE_CANDIDATE
    assert result.state == TradeFamilyState.CANDIDATE


def test_mubeen_high_risk_requires_approval():
    parsed = parse_message("mubeen", "High risk\n\nXAUUSD BUY NOW\nEnter 4603\nSL 4597\nTP1 4606")
    result = decide_signal(DecisionContext(provider_code="mubeen", parsed=parsed))
    assert result.action == DecisionAction.REQUIRE_APPROVAL
    assert result.state == TradeFamilyState.PENDING_APPROVAL
    assert result.requires_approval is True


def test_reenter_requires_approval():
    parsed = parse_message("mubeen", "Re enter\n\nXAUUSD BUY NOW\nEnter 4490\nSL 4479\nTP1 4494")
    result = decide_signal(DecisionContext(provider_code="mubeen", parsed=parsed))
    assert result.action == DecisionAction.REQUIRE_APPROVAL
    assert result.reason == "reenter_requires_approval"


def test_duplicate_is_ignored():
    parsed = parse_message("fredtrading", "BUY GOLD now\nSL 2010\nTP 2030")
    result = decide_signal(DecisionContext(provider_code="fredtrading", parsed=parsed, duplicate=True))
    assert result.action == DecisionAction.IGNORE_DUPLICATE
    assert result.state is None


def test_update_message_no_action_in_engine_core():
    parsed = parse_message("billionaire_club", "Position is running nicely! I will Move stop loss to break even!")
    result = decide_signal(DecisionContext(provider_code="billionaire_club", parsed=parsed))
    assert result.action == DecisionAction.NO_ACTION
    assert result.reason == "update_message_handled_elsewhere"
