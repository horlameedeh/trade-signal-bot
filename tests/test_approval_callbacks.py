import pytest
from sqlalchemy import text

from app.db.session import SessionLocal
from app.decision.engine import decide_signal
from app.decision.models import DecisionContext
from app.parsing.parser import parse_message
from app.services.approvals import create_approval_if_missing
from app.services.approval_callbacks import handle_approval_callback


pytestmark = pytest.mark.integration


def _cleanup_callback_test_artifacts() -> None:
    with SessionLocal() as db:
        db.execute(
            text(
                """
                CREATE TABLE IF NOT EXISTS control_actions (
                  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
                  telegram_user_id BIGINT,
                  control_chat_id BIGINT,
                  control_message_id BIGINT,
                  action TEXT NOT NULL,
                  payload JSONB NOT NULL DEFAULT '{}'::jsonb,
                  status TEXT NOT NULL DEFAULT 'queued'
                )
                """
            )
        )
        db.execute(
            text(
                """
                DELETE FROM control_actions
                WHERE payload->>'source' = 'approval_callback'
                   OR action IN ('approval_place', 'approval_ignore', 'approval_snooze')
                """
            )
        )
        db.execute(
            text(
                """
                DELETE FROM approvals
                WHERE plan_id IN (
                    SELECT p.plan_id
                    FROM trade_plans p
                    JOIN trade_intents i ON i.intent_id = p.intent_id
                    WHERE i.source_msg_pk = CAST('99999999-9999-9999-9999-999999999999' AS uuid)
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
                    WHERE source_msg_pk = CAST('99999999-9999-9999-9999-999999999999' AS uuid)
                )
                """
            )
        )
        db.execute(
            text(
                """
                DELETE FROM trade_intents
                WHERE source_msg_pk = CAST('99999999-9999-9999-9999-999999999999' AS uuid)
                """
            )
        )
        db.commit()


@pytest.fixture(autouse=True)
def _callback_test_cleanup():
    _cleanup_callback_test_artifacts()
    try:
        yield
    finally:
        _cleanup_callback_test_artifacts()


@pytest.fixture
def db_session():
    with SessionLocal() as db:
        try:
            yield db
        finally:
            db.rollback()


def _control_action_count(db_session) -> int:
    db_session.execute(
        text(
            """
            CREATE TABLE IF NOT EXISTS control_actions (
              id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
              created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
              telegram_user_id BIGINT,
              control_chat_id BIGINT,
              control_message_id BIGINT,
              action TEXT NOT NULL,
              payload JSONB NOT NULL DEFAULT '{}'::jsonb,
              status TEXT NOT NULL DEFAULT 'queued'
            )
            """
        )
    )
    return db_session.execute(text("SELECT COUNT(*) FROM control_actions")).scalar() or 0


def _build_high_risk_approval():
    parsed = parse_message("mubeen", "High risk\n\nXAUUSD BUY NOW\nEnter 4603\nSL 4597\nTP1 4606")
    decision = decide_signal(DecisionContext(provider_code="mubeen", parsed=parsed))
    card = create_approval_if_missing(
        source_msg_pk="99999999-9999-9999-9999-999999999999",
        provider_code="mubeen",
        parsed=parsed,
        decision=decision,
    )
    return card


def test_place_callback_creates_control_action(db_session):
    card = _build_high_risk_approval()
    before = _control_action_count(db_session)

    result = handle_approval_callback(
        callback_data=card.callback_place,
        telegram_user_id=12345,
        control_chat_id=-1005211338635,
        control_message_id=111,
    )

    after = _control_action_count(db_session)

    assert result.ok is True
    assert result.action.value == "place"
    assert result.approval_found is True
    assert result.control_action_created is True
    assert after == before + 1


def test_ignore_callback_creates_control_action(db_session):
    card = _build_high_risk_approval()
    before = _control_action_count(db_session)

    result = handle_approval_callback(
        callback_data=card.callback_ignore,
        telegram_user_id=12345,
        control_chat_id=-1005211338635,
        control_message_id=112,
    )

    after = _control_action_count(db_session)

    assert result.ok is True
    assert result.action.value == "ignore"
    assert result.control_action_created is True
    assert after == before + 1


def test_snooze_callback_creates_control_action(db_session):
    card = _build_high_risk_approval()
    before = _control_action_count(db_session)

    result = handle_approval_callback(
        callback_data=card.callback_snooze,
        telegram_user_id=12345,
        control_chat_id=-1005211338635,
        control_message_id=113,
    )

    after = _control_action_count(db_session)

    assert result.ok is True
    assert result.action.value == "snooze"
    assert result.control_action_created is True
    assert after == before + 1


def test_duplicate_same_callback_does_not_create_second_control_action(db_session):
    card = _build_high_risk_approval()
    before = _control_action_count(db_session)

    r1 = handle_approval_callback(
        callback_data=card.callback_place,
        telegram_user_id=12345,
        control_chat_id=-1005211338635,
        control_message_id=200,
    )
    r2 = handle_approval_callback(
        callback_data=card.callback_place,
        telegram_user_id=12345,
        control_chat_id=-1005211338635,
        control_message_id=200,
    )

    after = _control_action_count(db_session)

    assert r1.ok is True
    assert r1.control_action_created is True
    assert r2.ok is True
    assert r2.control_action_created is False
    assert after == before + 1


def test_unknown_fingerprint_fails_cleanly(db_session):
    result = handle_approval_callback(
        callback_data="approve:place:notarealfingerprint",
        telegram_user_id=12345,
        control_chat_id=-1005211338635,
        control_message_id=300,
    )

    assert result.ok is False
    assert result.approval_found is False
    assert result.reason == "approval_not_found"
