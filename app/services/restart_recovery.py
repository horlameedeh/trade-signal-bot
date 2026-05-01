from __future__ import annotations

from dataclasses import dataclass

from sqlalchemy import text

from app.db.session import SessionLocal
from app.execution.reconciliation import reconcile_open_positions
from app.execution.state_sync import sync_execution_state
from app.services.alerts import queue_control_alert, AlertPayload


@dataclass(frozen=True)
class RestartRecoveryResult:
    broker: str
    platform: str
    reconciliation_positions_seen: int
    tickets_inserted: int
    tickets_updated: int
    sync_positions_seen: int
    legs_confirmed_open: int
    legs_marked_closed: int
    families_recomputed: int
    management_actions_applied: int
    pending_control_actions: int
    pending_execution_retries: int
    dead_letters: int
    alert_queued: bool


def _count_pending_control_actions() -> int:
    with SessionLocal() as db:
        return (
            db.execute(
                text(
                    """
                    SELECT COUNT(*)
                    FROM control_actions
                    WHERE status IN ('queued', 'pending', 'failed')
                    """
                )
            ).scalar()
            or 0
        )


def _count_pending_execution_retries() -> int:
    with SessionLocal() as db:
        return (
            db.execute(
                text(
                    """
                    SELECT COUNT(*)
                    FROM control_actions
                    WHERE action = 'execution_retry'
                      AND status IN ('queued', 'pending', 'failed')
                    """
                )
            ).scalar()
            or 0
        )


def _count_dead_letters() -> int:
    with SessionLocal() as db:
        return (
            db.execute(
                text(
                    """
                    SELECT COUNT(*)
                    FROM control_actions
                    WHERE action LIKE 'dead_letter:%'
                    """
                )
            ).scalar()
            or 0
        )


def recover_after_restart(*, broker: str, platform: str, queue_alert: bool = True) -> RestartRecoveryResult:
    """
    Restart-safe recovery sequence.

    Important:
    - Does NOT place trades.
    - Reconciles broker positions into tickets.
    - Syncs local state against broker positions.
    - State sync recomputes lifecycle and resumes management rules.
    """
    reconciliation = reconcile_open_positions(broker=broker, platform=platform)
    sync = sync_execution_state(broker=broker, platform=platform)

    pending_control = _count_pending_control_actions()
    pending_retries = _count_pending_execution_retries()
    dead_letters = _count_dead_letters()

    alert_queued = False
    if queue_alert:
        queue_control_alert(
            AlertPayload(
                category="management_action",
                severity="info",
                title="Restart Recovery Completed",
                message="Restart recovery completed successfully.",
                broker=broker,
                platform=platform,
                data={
                    "reconciliation_positions_seen": reconciliation.positions_seen,
                    "tickets_inserted": reconciliation.tickets_inserted,
                    "tickets_updated": reconciliation.tickets_updated,
                    "sync_positions_seen": sync.broker_positions_seen,
                    "legs_confirmed_open": sync.legs_confirmed_open,
                    "legs_marked_closed": sync.legs_marked_closed,
                    "families_recomputed": sync.families_recomputed,
                    "management_actions_applied": sync.management_actions_applied,
                    "pending_control_actions": pending_control,
                    "pending_execution_retries": pending_retries,
                    "dead_letters": dead_letters,
                },
            )
        )
        alert_queued = True

    return RestartRecoveryResult(
        broker=broker,
        platform=platform,
        reconciliation_positions_seen=reconciliation.positions_seen,
        tickets_inserted=reconciliation.tickets_inserted,
        tickets_updated=reconciliation.tickets_updated,
        sync_positions_seen=sync.broker_positions_seen,
        legs_confirmed_open=sync.legs_confirmed_open,
        legs_marked_closed=sync.legs_marked_closed,
        families_recomputed=sync.families_recomputed,
        management_actions_applied=sync.management_actions_applied,
        pending_control_actions=pending_control,
        pending_execution_retries=pending_retries,
        dead_letters=dead_letters,
        alert_queued=alert_queued,
    )
