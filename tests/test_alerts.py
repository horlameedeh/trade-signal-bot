from app.services.alerts import AlertPayload, format_alert_message


def test_format_critical_alert():
    alert = AlertPayload(
        category="execution_failure",
        severity="critical",
        title="Execution Failure",
        message="Order failed.",
        family_id="fam-1",
        broker="ftmo",
        platform="mt5",
        symbol="XAUUSD",
        action_required="Review and retry.",
    )

    msg = format_alert_message(alert)

    assert "🚨 Execution Failure" in msg
    assert "Order failed." in msg
    assert "Broker: ftmo" in msg
    assert "Platform: mt5" in msg
    assert "Symbol: XAUUSD" in msg
    assert "Action required: Review and retry." in msg


def test_format_warning_alert():
    alert = AlertPayload(
        category="reconciliation_mismatch",
        severity="warning",
        title="Reconciliation Mismatch",
        message="Broker position not found locally.",
    )

    msg = format_alert_message(alert)

    assert "⚠️ Reconciliation Mismatch" in msg


def test_format_info_alert():
    alert = AlertPayload(
        category="trade_opened",
        severity="info",
        title="Trade Opened",
        message="Trade opened successfully.",
    )

    msg = format_alert_message(alert)

    assert "ℹ️ Trade Opened" in msg
