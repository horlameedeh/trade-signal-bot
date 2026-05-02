from __future__ import annotations

import argparse
import json
from dataclasses import asdict

from pathlib import Path

from dotenv import load_dotenv

from app.services.metrics import get_monitoring_snapshot


def main() -> int:
    load_dotenv(dotenv_path=Path(__file__).resolve().parent.parent / ".env")

    parser = argparse.ArgumentParser(description="Show TradeBot DB-backed metrics.")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    snapshot = get_monitoring_snapshot()
    data = asdict(snapshot)

    if args.json:
        print(json.dumps(data, indent=2, default=str))
        return 0

    print("TradeBot Metrics")
    print("----------------")
    print("Trades")
    for k, v in data["trade"].items():
        print(f"  {k}: {v}")

    print("\nExecution")
    for k, v in data["execution"].items():
        print(f"  {k}: {v}")

    print("\nLatency")
    for k, v in data["latency"].items():
        print(f"  {k}: {v}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
