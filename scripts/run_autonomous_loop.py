from __future__ import annotations

import argparse
import time
from dataclasses import asdict

from pathlib import Path

from dotenv import load_dotenv

from app.services.autonomous_runner import run_autonomous_cycle


def main() -> int:
    load_dotenv(dotenv_path=Path(__file__).resolve().parent.parent / ".env")

    parser = argparse.ArgumentParser(description="Run TradeBot autonomous production loop.")
    parser.add_argument("--broker", default="ftmo")
    parser.add_argument("--platform", default="mt5")
    parser.add_argument("--interval-seconds", type=int, default=30)
    parser.add_argument("--run-recovery-first", action="store_true")
    parser.add_argument("--monitor-every", type=int, default=20, help="Queue monitoring summary every N cycles.")
    parser.add_argument("--once", action="store_true")
    args = parser.parse_args()

    cycle = 0
    while True:
        cycle += 1

        result = run_autonomous_cycle(
            broker=args.broker,
            platform=args.platform,
            run_recovery=args.run_recovery_first and cycle == 1,
            queue_monitoring=(args.monitor_every > 0 and cycle % args.monitor_every == 0),
        )

        print(asdict(result), flush=True)

        if args.once:
            return 0 if result.ok else 1

        time.sleep(args.interval_seconds)


if __name__ == "__main__":
    raise SystemExit(main())
