import pytest
from sqlalchemy import text

from app.db.session import SessionLocal
from app.services.alerts import (
    alert_execution_failure,
    alert_management_action,
    alert_missing_symbol_mapping,
    alert_mt5_disconnected,
    alert_reconciliation_mismatch,
    alert_sl_tp_modified,
    alert_trade_closed,
    alert_trade_opened,
)


pytestmark = pytest.mark.integration


@pytest.fixture
def db_session():
    with SessionLocal() as db:
        try:
            yield db
        finally:
            db.rollback()


def _latest_alert(db_session):
    return db_session.execute(
        text(
            """
            SELECT action, status, payload
            FROM control_actions
            WHERE action LIKE 'alert:%'
            ORDER BY created_at DESC
            LIMIT 1
            """
        )
    ).mappings().first()


def test_execution_failure_alert_queued(db_session):
    result = alert_execution_failure(
        message="order_send failed",
        family_id="fam-1",
        broker="ftmo",
        platform="mt5",
        symbol="XAUUSD",
        data={"retcode": 10018},
    )

    assert result.queued is True
    row = _latest_alert(db_session)

    assert row["action"] == "alert:execution_failure"
    assert row["status"] == "queued"
    assert row["payload"]["severity"] == "critical"
    assert row["payload"]["category"] == "execution_failure"
    assert "order_send failed" in row["payload"]["formatted"]


def test_missing_symbol_mapping_alert_queued(db_session):
    alert_missing_symbol_mapping(symbol="UNKNOWN", broker="ftmo", platform="mt5")

    row = _latest_alert(db_session)

    assert row["action"] == "alert:missing_symbol_mapping"
    assert row["payload"]["symbol"] == "UNKNOWN"
    assert "Add symbol mapping" in row["payload"]["formatted"]


def test_reconciliation_alert_queued(db_session):
    alert_reconciliation_mismatch(
        message="Broker has unmatched position.",
        broker="ftmo",
        platform="mt5",
    )

    row = _latest_alert(db_session)

    assert row["action"] == "alert:reconciliation_mismatch"
    assert row["payload"]["severity"] == "warning"


def test_mt5_disconnected_alert_queued(db_session):
    alert_mt5_disconnected(
        broker="ftmo",
        platform="mt5",
        detail="Health check failed.",
    )

    row = _latest_alert(db_session)

    assert row["action"] == "alert:mt5_disconnected"
    assert row["payload"]["severity"] == "critical"


def test_trade_lifecycle_alerts_queued(db_session):
    alert_trade_opened(family_id="fam-1", broker="ftmo", platform="mt5", symbol="XAUUSD")
    row = _latest_alert(db_session)
    assert row["action"] == "alert:trade_opened"

    alert_sl_tp_modified(family_id="fam-1", broker="ftmo", platform="mt5", symbol="XAUUSD")
    row = _latest_alert(db_session)
    assert row["action"] == "alert:sl_tp_modified"

    alert_trade_closed(family_id="fam-1", broker="ftmo", platform="mt5", symbol="XAUUSD")
    row = _latest_alert(db_session)
    assert row["action"] == "alert:trade_closed"

    alert_management_action(family_id="fam-1", message="Moved SL to entry.")
    row = _latest_alert(db_session)
    assert row["action"] == "alert:management_action"
