import pytest
from sqlalchemy import text

from app.db.session import SessionLocal
from app.services.monitoring_summary import format_monitoring_summary, queue_monitoring_summary


pytestmark = pytest.mark.integration


@pytest.fixture
def db_session():
    with SessionLocal() as db:
        try:
            db.execute(text("DELETE FROM control_actions WHERE payload->>'title' = 'TradeBot Monitoring Summary'"))
            db.commit()
            yield db
        finally:
            db.execute(text("DELETE FROM control_actions WHERE payload->>'title' = 'TradeBot Monitoring Summary'"))
            db.commit()


def test_format_monitoring_summary_contains_sections(db_session):
    summary = format_monitoring_summary()

    assert "TradeBot Monitoring Summary" in summary
    assert "Trades" in summary
    assert "Execution" in summary
    assert "Latency" in summary
    assert "Win rate" in summary


def test_queue_monitoring_summary_creates_control_action(db_session):
    queue_monitoring_summary()

    row = db_session.execute(
        text(
            """
            SELECT action, status, payload
            FROM control_actions
            WHERE payload->>'title' = 'TradeBot Monitoring Summary'
            ORDER BY created_at DESC
            LIMIT 1
            """
        )
    ).mappings().first()

    assert row is not None
    assert row["action"] == "alert:management_action"
    assert row["status"] == "queued"
    assert row["payload"]["title"] == "TradeBot Monitoring Summary"
    assert "trade" in row["payload"]["data"]
    assert "execution" in row["payload"]["data"]
    assert "latency" in row["payload"]["data"]
