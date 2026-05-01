import pytest

from app.execution.retry import RetryPolicy, compute_backoff_delay, run_with_retry


def test_compute_backoff_delay():
    policy = RetryPolicy(max_attempts=3, base_delay_seconds=1.0, backoff_multiplier=2.0)

    assert compute_backoff_delay(attempt_number=1, policy=policy) == 0.0
    assert compute_backoff_delay(attempt_number=2, policy=policy) == 1.0
    assert compute_backoff_delay(attempt_number=3, policy=policy) == 2.0


def test_run_with_retry_succeeds_after_transient_failure(monkeypatch):
    calls = {"n": 0}
    sleeps = []

    def op():
        calls["n"] += 1
        if calls["n"] < 2:
            raise RuntimeError("temporary")
        return "ok"

    result, attempts, error = run_with_retry(
        family_id="00000000-0000-0000-0000-000000000000",
        operation=op,
        policy=RetryPolicy(max_attempts=3, base_delay_seconds=1.0),
        sleep_fn=sleeps.append,
    )

    assert result == "ok"
    assert attempts == 2
    assert error is None
    assert sleeps == [1.0]


def test_run_with_retry_returns_error_after_max_attempts():
    sleeps = []

    def op():
        raise RuntimeError("boom")

    result, attempts, error = run_with_retry(
        family_id="00000000-0000-0000-0000-000000000000",
        operation=op,
        policy=RetryPolicy(max_attempts=2, base_delay_seconds=1.0),
        sleep_fn=sleeps.append,
    )

    assert result is None
    assert attempts == 2
    assert error == "boom"
    assert sleeps == [1.0]
