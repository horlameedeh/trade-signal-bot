import pytest
from sqlalchemy import text

from app.db.session import SessionLocal
from app.parsing.parser import parse_message
from app.services.decision_flow import process_decision_flow


pytestmark = pytest.mark.integration


@pytest.fixture
def db_session():
    with SessionLocal() as db:
        try:
            yield db
        finally:
            db.rollback()


def _approval_count(db_session) -> int:
    return db_session.execute(text("SELECT COUNT(*) FROM approvals")).scalar() or 0


def test_high_risk_creates_approval(db_session):
    before = _approval_count(db_session)

    parsed = parse_message("mubeen", "High risk\n\nXAUUSD BUY NOW\nEnter 4603\nSL 4597\nTP1 4606")
    result = process_decision_flow(
        source_msg_pk="44444444-4444-4444-4444-444444444444",
        provider_code="mubeen",
        parsed=parsed,
        duplicate=False,
        risk_checks_pass=True,
    )

    after = _approval_count(db_session)

    assert result.decision.action.value == "REQUIRE_APPROVAL"
    assert result.approval_card is not None
    assert after == before + 1


def test_duplicate_does_not_create_second_approval(db_session):
    source_msg_pk = "55555555-5555-5555-5555-555555555555"
    parsed = parse_message("mubeen", "High risk\n\nXAUUSD BUY NOW\nEnter 4603\nSL 4597\nTP1 4606")

    before = _approval_count(db_session)

    r1 = process_decision_flow(
        source_msg_pk=source_msg_pk,
        provider_code="mubeen",
        parsed=parsed,
        duplicate=False,
        risk_checks_pass=True,
    )
    r2 = process_decision_flow(
        source_msg_pk=source_msg_pk,
        provider_code="mubeen",
        parsed=parsed,
        duplicate=True,
        risk_checks_pass=True,
    )

    after = _approval_count(db_session)

    assert r1.approval_card is not None
    assert r2.approval_card is None
    assert after == before + 1


def test_unofficial_trade_becomes_candidate_no_approval_yet(db_session):
    before = _approval_count(db_session)

    parsed = parse_message("fredtrading", "BUY GOLD now\n(not official)\nSL 2010\nTP 2030")
    result = process_decision_flow(
        source_msg_pk="66666666-6666-6666-6666-666666666666",
        provider_code="fredtrading",
        parsed=parsed,
        duplicate=False,
        risk_checks_pass=True,
    )

    after = _approval_count(db_session)

    assert result.decision.action.value == "CREATE_CANDIDATE"
    assert result.persisted_state == "CANDIDATE"
    assert result.approval_card is None
    assert after == before


def test_stub_trade_becomes_pending_update_no_approval_yet(db_session):
    before = _approval_count(db_session)

    parsed = parse_message("fredtrading", "Buy gold now 29")
    result = process_decision_flow(
        source_msg_pk="77777777-7777-7777-7777-777777777777",
        provider_code="fredtrading",
        parsed=parsed,
        duplicate=False,
        risk_checks_pass=True,
    )

    after = _approval_count(db_session)

    assert result.decision.action.value == "PENDING_UPDATE"
    assert result.persisted_state == "PENDING_UPDATE"
    assert result.approval_card is None
    assert after == before


def test_complete_trade_auto_place_no_approval(db_session):
    before = _approval_count(db_session)

    parsed = parse_message("fredtrading", "BUY GOLD now\nSL 2010\nTP 2030 2040")
    result = process_decision_flow(
        source_msg_pk="88888888-8888-8888-8888-888888888888",
        provider_code="fredtrading",
        parsed=parsed,
        duplicate=False,
        risk_checks_pass=True,
    )

    after = _approval_count(db_session)

    assert result.decision.action.value == "AUTO_PLACE"
    assert result.persisted_state == "OPEN"
    assert result.approval_card is None
    assert after == before
