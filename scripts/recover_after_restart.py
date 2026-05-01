from __future__ import annotations

import argparse
import sys

from app.services.restart_recovery import recover_after_restart


def main() -> int:
    parser = argparse.ArgumentParser(description="Run restart recovery for an execution node.")
    parser.add_argument("--broker", required=True)
    parser.add_argument("--platform", required=True)
    parser.add_argument("--no-alert", action="store_true")
    args = parser.parse_args()

    try:
        result = recover_after_restart(
            broker=args.broker,
            platform=args.platform,
            queue_alert=not args.no_alert,
        )
    except RuntimeError as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1

    print(result)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
