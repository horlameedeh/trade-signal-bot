from datetime import datetime, timedelta, timezone

from app.services.timeouts import TimeoutAction, TimeoutPolicy, evaluate_timeout


def _now():
    return datetime.now(timezone.utc)


def test_candidate_before_timeout_does_nothing():
    now = _now()
    created_at = now - timedelta(minutes=9)

    result = evaluate_timeout(
        state="CANDIDATE",
        created_at=created_at,
        now=now,
    )

    assert result.action == TimeoutAction.NONE
    assert result.reason == "no_timeout_action"


def test_candidate_at_10_minutes_requires_approval():
    now = _now()
    created_at = now - timedelta(minutes=10)

    result = evaluate_timeout(
        state="CANDIDATE",
        created_at=created_at,
        now=now,
    )

    assert result.action == TimeoutAction.REQUIRE_APPROVAL
    assert result.reason == "candidate_timeout_requires_approval"


def test_pending_update_at_30_minutes_alerts_and_requires_approval():
    now = _now()
    created_at = now - timedelta(minutes=30)

    result = evaluate_timeout(
        state="PENDING_UPDATE",
        created_at=created_at,
        now=now,
    )

    assert result.action == TimeoutAction.ALERT_AND_APPROVAL
    assert result.reason == "pending_update_timeout_alert_and_approval"


def test_unresolved_after_2_hours_escalates():
    now = _now()
    created_at = now - timedelta(minutes=120)

    result = evaluate_timeout(
        state="PENDING_UPDATE",
        created_at=created_at,
        now=now,
    )

    assert result.action == TimeoutAction.ESCALATE
    assert result.reason == "timeout_escalation"


def test_pending_approval_after_2_hours_escalates():
    now = _now()
    created_at = now - timedelta(minutes=130)

    result = evaluate_timeout(
        state="PENDING_APPROVAL",
        created_at=created_at,
        now=now,
    )

    assert result.action == TimeoutAction.ESCALATE


def test_open_trade_has_no_timeout_action():
    now = _now()
    created_at = now - timedelta(minutes=300)

    result = evaluate_timeout(
        state="OPEN",
        created_at=created_at,
        now=now,
    )

    assert result.action == TimeoutAction.NONE


def test_custom_policy_can_override_thresholds():
    now = _now()
    created_at = now - timedelta(minutes=5)

    result = evaluate_timeout(
        state="CANDIDATE",
        created_at=created_at,
        now=now,
        policy=TimeoutPolicy(candidate_minutes=5, pending_update_minutes=7, escalate_minutes=20),
    )

    assert result.action == TimeoutAction.REQUIRE_APPROVAL
