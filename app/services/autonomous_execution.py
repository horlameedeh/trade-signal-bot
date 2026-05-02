from __future__ import annotations

from dataclasses import dataclass

from sqlalchemy import text

from app.db.session import SessionLocal
from app.execution.guarded_live_executor import GuardedExecutionResult, execute_family_with_prop_guard
from app.execution.http_node import HttpExecutionNode
from app.execution.node_registry import get_active_execution_node
from app.services.alerts import alert_execution_failure


@dataclass(frozen=True)
class AutonomousExecutionResult:
    families_seen: int
    attempted: int
    executed: int
    blocked: int
    requires_approval: int
    failed: int


def find_executable_families(*, broker: str, platform: str, limit: int = 20) -> list[str]:
    """
    Finds currently OPEN families for this broker/platform that have no execution tickets yet.
    This is idempotent because already-ticketed families are skipped.
    """
    with SessionLocal() as db:
        rows = db.execute(
            text(
                """
                SELECT tf.family_id::text AS family_id
                FROM trade_families tf
                JOIN broker_accounts ba ON ba.account_id = tf.account_id
                LEFT JOIN trade_legs tl ON tl.family_id = tf.family_id
                LEFT JOIN execution_tickets et ON et.leg_id = tl.leg_id
                WHERE tf.state = 'OPEN'
                  AND ba.broker = :broker
                  AND ba.platform = :platform
                  AND ba.is_active = true
                                    AND NOT EXISTS (
                                        SELECT 1
                                        FROM telegram_messages tm
                                        WHERE tm.msg_pk = tf.source_msg_pk
                                            AND tm.raw_json->>'source' = 'telethon_ingestion'
                                            AND tm.raw_json->>'dry_run' = 'true'
                                    )
                GROUP BY tf.family_id, tf.created_at
                HAVING COUNT(et.ticket_id) = 0
                ORDER BY tf.created_at ASC
                LIMIT :limit
                """
            ),
            {"broker": broker, "platform": platform, "limit": limit},
        ).mappings().all()

    return [r["family_id"] for r in rows]


def process_autonomous_executions(
    *,
    broker: str,
    platform: str,
    limit: int = 20,
) -> AutonomousExecutionResult:
    family_ids = find_executable_families(broker=broker, platform=platform, limit=limit)

    if not family_ids:
        return AutonomousExecutionResult(
            families_seen=0,
            attempted=0,
            executed=0,
            blocked=0,
            requires_approval=0,
            failed=0,
        )

    node = get_active_execution_node(broker=broker, platform=platform)
    adapter = HttpExecutionNode(node.base_url)

    attempted = 0
    executed = 0
    blocked = 0
    requires_approval = 0
    failed = 0

    for family_id in family_ids:
        attempted += 1

        try:
            result: GuardedExecutionResult = execute_family_with_prop_guard(
                family_id=family_id,
                adapter=adapter,
            )

            if result.execution_result and result.execution_result.sent > 0:
                executed += 1
            elif result.blocked:
                blocked += 1
            elif result.requires_approval:
                requires_approval += 1

        except Exception as exc:
            failed += 1
            alert_execution_failure(
                message=f"Autonomous execution failed for family {family_id}: {exc}",
                family_id=family_id,
                broker=broker,
                platform=platform,
                data={"component": "autonomous_execution"},
            )

    return AutonomousExecutionResult(
        families_seen=len(family_ids),
        attempted=attempted,
        executed=executed,
        blocked=blocked,
        requires_approval=requires_approval,
        failed=failed,
    )
