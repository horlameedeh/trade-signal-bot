from __future__ import annotations

import argparse
import sys

from app.execution.reconciliation import reconcile_open_positions


def main() -> int:
    parser = argparse.ArgumentParser(description="Reconcile open broker positions from an execution node.")
    parser.add_argument("--broker", required=True, help="Broker code (e.g., ftmo)")
    parser.add_argument("--platform", required=True, help="Trading platform (e.g., mt5)")
    args = parser.parse_args()

    try:
        result = reconcile_open_positions(broker=args.broker, platform=args.platform)
        print(result)
        return 0
    except RuntimeError as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
