import pytest
from sqlalchemy import text
from uuid import uuid4

from app.db.session import SessionLocal
from app.decision.engine import decide_signal
from app.decision.models import DecisionContext
from app.parsing.parser import parse_message
from app.services.approvals import build_approval_card, create_approval_if_missing


pytestmark = pytest.mark.integration


def _cleanup_approval_artifacts() -> None:
    with SessionLocal() as db:
        db.execute(
            text(
                """
                DELETE FROM approvals
                WHERE plan_id IN (
                    SELECT p.plan_id
                    FROM trade_plans p
                    JOIN trade_intents i ON i.intent_id = p.intent_id
                    WHERE i.meta->>'source' = 'approvals_service'
                )
                """
            )
        )
        db.execute(
            text(
                """
                DELETE FROM trade_plans
                WHERE intent_id IN (
                    SELECT intent_id
                    FROM trade_intents
                    WHERE meta->>'source' = 'approvals_service'
                )
                """
            )
        )
        db.execute(
            text(
                """
                DELETE FROM trade_intents
                WHERE meta->>'source' = 'approvals_service'
                """
            )
        )
        db.commit()


@pytest.fixture(autouse=True)
def _approvals_test_cleanup():
    _cleanup_approval_artifacts()
    try:
        yield
    finally:
        _cleanup_approval_artifacts()


@pytest.fixture
def db_session():
    with SessionLocal() as db:
        try:
            yield db
        finally:
            db.rollback()


def _approval_count(db_session) -> int:
    return db_session.execute(text("SELECT COUNT(*) FROM approvals")).scalar() or 0


def test_build_approval_card_contains_required_fields():
    parsed = parse_message("mubeen", "High risk\n\nXAUUSD BUY NOW\nEnter 4603\nSL 4597\nTP1 4606")
    decision = decide_signal(DecisionContext(provider_code="mubeen", parsed=parsed))

    card = build_approval_card(
        source_msg_pk="11111111-1111-1111-1111-111111111111",
        provider_code="mubeen",
        parsed=parsed,
        decision=decision,
    )

    assert card.provider == "mubeen"
    assert card.category == "HIGH_RISK"
    assert card.symbol == "XAUUSD"
    assert card.side == "BUY"
    assert card.entry == "4603"
    assert card.sl == "4597"
    assert card.tps == ["4606"]
    assert "Reason:" in card.message
    assert card.callback_place.startswith("approve:place:")
    assert card.callback_ignore.startswith("approve:ignore:")
    assert card.callback_snooze.startswith("approve:snooze:")
    assert len(card.callback_place) <= 64
    assert len(card.callback_ignore) <= 64
    assert len(card.callback_snooze) <= 64


def test_duplicate_message_does_not_create_duplicate_approval(db_session):
    before = _approval_count(db_session)

    parsed = parse_message("mubeen", "High risk\n\nXAUUSD BUY NOW\nEnter 4603\nSL 4597\nTP1 4606")
    decision = decide_signal(DecisionContext(provider_code="mubeen", parsed=parsed))

    source_msg_pk = str(uuid4())

    create_approval_if_missing(
        source_msg_pk=source_msg_pk,
        provider_code="mubeen",
        parsed=parsed,
        decision=decision,
    )
    create_approval_if_missing(
        source_msg_pk=source_msg_pk,
        provider_code="mubeen",
        parsed=parsed,
        decision=decision,
    )

    after = _approval_count(db_session)
    assert after == before + 1


def test_unofficial_trade_creates_approval_card_payload(db_session):
    parsed = parse_message("fredtrading", "BUY GOLD now\n(not official)\nSL 2010\nTP 2030")
    decision = decide_signal(DecisionContext(provider_code="fredtrading", parsed=parsed))

    # decision engine creates candidate, but approval card builder should still be deterministic
    card = build_approval_card(
        source_msg_pk="33333333-3333-3333-3333-333333333333",
        provider_code="fredtrading",
        parsed=parsed,
        decision=decision,
    )

    assert card.category == "UNOFFICIAL"
    assert card.symbol == "XAUUSD"
    assert "UNOFFICIAL" in card.message or "unofficial" in card.message.lower()
