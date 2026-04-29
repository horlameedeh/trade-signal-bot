from __future__ import annotations

from dataclasses import dataclass

from sqlalchemy import text

from app.db.session import SessionLocal


@dataclass(frozen=True)
class ExecutionNodeRecord:
    node_id: str
    name: str
    broker: str
    platform: str
    base_url: str


def get_active_execution_node(*, broker: str, platform: str) -> ExecutionNodeRecord:
    with SessionLocal() as db:
        row = db.execute(
            text(
                """
                SELECT node_id::text, name, broker, platform, base_url
                FROM execution_nodes
                WHERE broker = :broker
                  AND platform = :platform
                  AND is_active = true
                ORDER BY created_at DESC
                LIMIT 1
                """
            ),
            {"broker": broker, "platform": platform},
        ).mappings().first()

    if not row:
        raise RuntimeError(
            f"No active execution node configured for broker={broker} platform={platform}. "
            f"Please register an execution node in the execution_nodes table with: "
            f"broker='{broker}', platform='{platform}', base_url=<node_url>, is_active=true"
        )

    if not row["base_url"]:
        raise RuntimeError(
            f"Execution node '{row['name']}' for broker={broker} platform={platform} "
            f"has no base_url configured. Please set the base_url in the execution_nodes table."
        )

    return ExecutionNodeRecord(
        node_id=row["node_id"],
        name=row["name"],
        broker=row["broker"],
        platform=row["platform"],
        base_url=row["base_url"],
    )
