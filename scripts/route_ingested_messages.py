from __future__ import annotations

import argparse

from dotenv import load_dotenv

from app.telegram.ingestion_router import route_ingested_messages_dry_run


def main() -> int:
    load_dotenv()

    parser = argparse.ArgumentParser()
    parser.add_argument("--limit", type=int, default=50)
    args = parser.parse_args()

    result = route_ingested_messages_dry_run(limit=args.limit)
    print(result)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())