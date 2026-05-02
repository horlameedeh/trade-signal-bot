from __future__ import annotations

from dotenv import load_dotenv

from pathlib import Path

from app.services.monitoring_summary import format_monitoring_summary, queue_monitoring_summary


def main() -> int:
    load_dotenv(dotenv_path=Path(__file__).resolve().parent.parent / ".env")

    queue_monitoring_summary()
    print(format_monitoring_summary())
    print("\nQueued monitoring summary for Control Chat.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
