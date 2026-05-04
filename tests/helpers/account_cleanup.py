from __future__ import annotations

from sqlalchemy import text


def deactivate_active_accounts_for_broker_platform(
    db_session,
    *,
    broker: str,
    platform: str = "mt5",
) -> None:
    """
    Test-only helper.

    Prevents integration tests from colliding with the production-style
    partial unique index on one active account per broker/platform.
    """
    db_session.execute(
        text(
            """
            UPDATE broker_accounts
            SET is_active = false
            WHERE broker::text = :broker
              AND platform::text = :platform
              AND is_active = true
            """
        ),
        {"broker": broker, "platform": platform},
    )
    db_session.commit()


def deactivate_named_test_accounts(db_session) -> None:
    """
    Test-only cleanup for known fixture labels.
    Never touches real execution labels.
    """
    db_session.execute(
        text(
            """
            UPDATE broker_accounts
            SET is_active = false
            WHERE (
                label ILIKE '%seed%'
             OR label ILIKE '%test%'
             OR label ILIKE '%smoke%'
             OR label ILIKE '%sim%'
             OR label ILIKE '%dry-run%'
             OR label ILIKE '%svc%'
             OR label ILIKE '%metrics%'
             OR label ILIKE '%restart-recovery%'
             OR label ILIKE '%guard-retry%'
             OR label ILIKE '%risk-seed%'
            )
            AND label NOT IN (
              'FTMO - Execution',
              'FundedNext - Execution',
              'Vantage - Execution',
              'StarTrader - Execution',
              'Bullwaves - Execution'
            )
            """
        )
    )
    db_session.commit()