from app.risk.prop_rules import PropRiskInput, evaluate_prop_risk


def test_ftmo_allows_trade_within_limits():
    result = evaluate_prop_risk(
        PropRiskInput(
            broker="ftmo",
            account_equity="10000",
            starting_balance="10000",
            daily_realized_pnl="0",
            total_realized_pnl="0",
            current_open_risk="100",
            new_trade_risk_at_sl="100",
        )
    )

    assert result.decision == "allow"
    assert "within_prop_risk_limits" in result.reasons


def test_ftmo_blocks_when_daily_loss_limit_breached():
    result = evaluate_prop_risk(
        PropRiskInput(
            broker="ftmo",
            account_equity="10000",
            starting_balance="10000",
            daily_realized_pnl="-400",
            total_realized_pnl="-400",
            current_open_risk="50",
            new_trade_risk_at_sl="50",
        )
    )

    assert result.decision == "block"
    assert "daily_loss_limit_breached" in result.reasons


def test_ftmo_blocks_when_total_loss_limit_breached():
    result = evaluate_prop_risk(
        PropRiskInput(
            broker="ftmo",
            account_equity="10000",
            starting_balance="10000",
            daily_realized_pnl="0",
            total_realized_pnl="-950",
            current_open_risk="25",
            new_trade_risk_at_sl="25",
        )
    )

    assert result.decision == "block"
    assert "total_loss_limit_breached" in result.reasons


def test_near_limit_requires_approval():
    result = evaluate_prop_risk(
        PropRiskInput(
            broker="ftmo",
            account_equity="10000",
            starting_balance="10000",
            daily_realized_pnl="-350",
            total_realized_pnl="-350",
            current_open_risk="25",
            new_trade_risk_at_sl="25",
        )
    )

    assert result.decision == "require_approval"
    assert "near_daily_loss_limit" in result.reasons


def test_missing_profile_blocks():
    result = evaluate_prop_risk(
        PropRiskInput(
            broker="unknownbroker",
            account_equity="10000",
            starting_balance="10000",
            daily_realized_pnl="0",
            total_realized_pnl="0",
            current_open_risk="0",
            new_trade_risk_at_sl="10",
        )
    )

    assert result.decision == "block"
    assert "missing_prop_risk_profile:unknownbroker" in result.reasons


def test_traderscale_profile_available():
    result = evaluate_prop_risk(
        PropRiskInput(
            broker="traderscale",
            account_equity="100000",
            starting_balance="100000",
            daily_realized_pnl="0",
            total_realized_pnl="0",
            current_open_risk="1000",
            new_trade_risk_at_sl="1000",
        )
    )

    assert result.decision == "allow"


def test_fundednext_placeholder_profile_available():
    result = evaluate_prop_risk(
        PropRiskInput(
            broker="fundednext",
            account_equity="100000",
            starting_balance="100000",
            daily_realized_pnl="0",
            total_realized_pnl="0",
            current_open_risk="1000",
            new_trade_risk_at_sl="1000",
        )
    )

    assert result.decision == "allow"
