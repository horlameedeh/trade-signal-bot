from __future__ import annotations

import argparse
import time

from app.execution.terminal_heartbeat import (
    mark_terminal_session_stopped,
    touch_terminal_session,
)


def main() -> int:
    parser = argparse.ArgumentParser(description="Update terminal_sessions.last_heartbeat.")
    parser.add_argument("--session-id", required=True)
    parser.add_argument("--status", default="running", choices=["starting", "running"])
    parser.add_argument("--interval-seconds", type=int, default=0)
    parser.add_argument("--once", action="store_true")
    parser.add_argument("--mark-stopped", action="store_true")

    args = parser.parse_args()

    if args.mark_stopped:
        result = mark_terminal_session_stopped(session_id=args.session_id)
        print(result)
        return 0 if result.updated else 1

    while True:
        result = touch_terminal_session(session_id=args.session_id, status=args.status)
        print(result, flush=True)

        if not result.updated:
            return 1

        if args.once or args.interval_seconds <= 0:
            return 0

        time.sleep(args.interval_seconds)


if __name__ == "__main__":
    raise SystemExit(main())
