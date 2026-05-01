from __future__ import annotations

import argparse
import sys

from app.execution.state_sync import sync_execution_state


def main() -> int:
    parser = argparse.ArgumentParser(description="Sync local trade state with broker open positions.")
    parser.add_argument("--broker", required=True)
    parser.add_argument("--platform", required=True)
    args = parser.parse_args()

    try:
        result = sync_execution_state(broker=args.broker, platform=args.platform)
    except RuntimeError as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1

    print(result)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
