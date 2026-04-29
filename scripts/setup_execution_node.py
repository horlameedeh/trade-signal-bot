"""Setup script to configure an execution node in the database.

This script allows you to register a new execution node for testing or production use.

Example usage:
    python scripts/setup_execution_node.py --broker ftmo --platform mt5 --url http://localhost:8000
"""

from __future__ import annotations

import argparse
import sys

from sqlalchemy import text

from app.db.session import SessionLocal


def main() -> int:
    parser = argparse.ArgumentParser(description="Setup an execution node for position reconciliation.")
    parser.add_argument("--broker", required=True, help="Broker code (e.g., ftmo, vantage)")
    parser.add_argument("--platform", required=True, help="Trading platform (e.g., mt5, mt4)")
    parser.add_argument("--url", required=True, help="Base URL of the execution node (e.g., http://localhost:8000)")
    parser.add_argument("--name", help="Node name (optional, defaults to broker-platform)")
    parser.add_argument("--inactive", action="store_true", help="Create the node as inactive")
    args = parser.parse_args()

    node_name = args.name or f"{args.broker}-{args.platform}"
    is_active = not args.inactive

    try:
        with SessionLocal() as db:
            # Check if node already exists
            existing = db.execute(
                text(
                    """
                    SELECT node_id
                    FROM execution_nodes
                    WHERE broker = :broker AND platform = :platform AND name = :name
                    """
                ),
                {"broker": args.broker, "platform": args.platform, "name": node_name},
            ).scalar()

            if existing:
                print(f"Node already exists: {node_name} ({args.broker}/{args.platform})")
                # Update the URL and active status
                db.execute(
                    text(
                        """
                        UPDATE execution_nodes
                        SET base_url = :url, is_active = :is_active, created_at = now()
                        WHERE broker = :broker AND platform = :platform AND name = :name
                        """
                    ),
                    {"url": args.url, "is_active": is_active, "broker": args.broker, "platform": args.platform, "name": node_name},
                )
                print(f"Updated existing node")
            else:
                # Create new node
                db.execute(
                    text(
                        """
                        INSERT INTO execution_nodes (name, broker, platform, base_url, is_active, meta)
                        VALUES (:name, :broker, :platform, :url, :is_active, '{}'::jsonb)
                        """
                    ),
                    {
                        "name": node_name,
                        "broker": args.broker,
                        "platform": args.platform,
                        "url": args.url,
                        "is_active": is_active,
                    },
                )
                print(f"Created new node: {node_name}")

            db.commit()
            
            # Display the configured node
            node = db.execute(
                text(
                    """
                    SELECT node_id::text, name, broker, platform, base_url, is_active
                    FROM execution_nodes
                    WHERE broker = :broker AND platform = :platform AND name = :name
                    """
                ),
                {"broker": args.broker, "platform": args.platform, "name": node_name},
            ).mappings().first()

            print(f"\nExecution Node Configuration:")
            print(f"  ID:       {node['node_id']}")
            print(f"  Name:     {node['name']}")
            print(f"  Broker:   {node['broker']}")
            print(f"  Platform: {node['platform']}")
            print(f"  URL:      {node['base_url']}")
            print(f"  Active:   {node['is_active']}")
            return 0

    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
