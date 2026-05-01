from __future__ import annotations

import argparse
import sys

from app.execution.node_health import check_execution_node_health


def main() -> int:
    parser = argparse.ArgumentParser(description="Check execution node health and queue alert if unhealthy.")
    parser.add_argument("--broker", required=True)
    parser.add_argument("--platform", required=True)
    parser.add_argument("--timeout", type=float, default=5.0)
    args = parser.parse_args()

    try:
        result = check_execution_node_health(
            broker=args.broker,
            platform=args.platform,
            timeout=args.timeout,
        )
    except RuntimeError as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1

    print(result)
    return 0 if result.ok and result.terminal_connected else 2


if __name__ == "__main__":
    raise SystemExit(main())
