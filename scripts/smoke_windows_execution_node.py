from __future__ import annotations

import argparse

from sqlalchemy import text

from app.db.session import SessionLocal
from app.execution.http_node import HttpExecutionNode
from app.execution.live_executor import execute_family_live
from app.execution.node_registry import get_active_execution_node


def latest_family_for_broker(*, broker: str, platform: str) -> str:
    with SessionLocal() as db:
        family_id = db.execute(
            text(
                """
                SELECT tf.family_id::text
                FROM trade_families tf
                JOIN broker_accounts ba ON ba.account_id = tf.account_id
                WHERE ba.broker = :broker
                  AND ba.platform = :platform
                  AND tf.state = 'OPEN'
                ORDER BY tf.created_at DESC
                LIMIT 1
                """
            ),
            {"broker": broker, "platform": platform},
        ).scalar()

    if not family_id:
        raise SystemExit(f"No OPEN trade_family found for broker={broker} platform={platform}")

    return family_id


def main() -> int:
    parser = argparse.ArgumentParser(description="Send an OPEN family to the configured Windows execution node.")
    parser.add_argument("--broker", default="vantage")
    parser.add_argument("--platform", default="stub")
    parser.add_argument("--family-id")
    args = parser.parse_args()

    node = get_active_execution_node(broker=args.broker, platform=args.platform)
    family_id = args.family_id or latest_family_for_broker(broker=args.broker, platform=args.platform)

    print(f"node={node.name} {node.base_url}")
    print(f"family_id={family_id}")

    adapter = HttpExecutionNode(node.base_url)
    result = execute_family_live(family_id=family_id, adapter=adapter)

    print(result)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
