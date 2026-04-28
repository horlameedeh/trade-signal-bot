from __future__ import annotations

import argparse
import json
from dataclasses import asdict

from sqlalchemy import text

from app.db.session import SessionLocal
from app.services.dry_run_pipeline import process_message_dry_run


def _load_messages(*, provider: str | None, limit: int, newest_first: bool = False) -> list[tuple[int, int]]:
    order = "DESC" if newest_first else "ASC"
    with SessionLocal() as db:
        rows = db.execute(
            text(
                f"""
                SELECT tm.chat_id, tm.message_id
                FROM telegram_messages tm
                JOIN telegram_chats tc ON tc.chat_id = tm.chat_id
                WHERE tm.text IS NOT NULL
                  AND (
                    CAST(:provider AS text) IS NULL
                    OR CAST(tc.provider_code AS text) = CAST(:provider AS text)
                  )
                ORDER BY tm.created_at {order}
                LIMIT :limit
                """
            ),
            {"provider": provider, "limit": limit},
        ).all()

    return [(int(chat_id), int(message_id)) for chat_id, message_id in rows]


def main() -> int:
    parser = argparse.ArgumentParser(description="Replay historical Telegram messages through the dry-run pipeline.")
    parser.add_argument("--provider", help="Optional provider_code filter.")
    parser.add_argument("--limit", type=int, default=50)
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--newest-first", action="store_true")
    args = parser.parse_args()

    messages = _load_messages(
        provider=args.provider,
        limit=args.limit,
        newest_first=args.newest_first,
    )
    results = [
        process_message_dry_run(chat_id=chat_id, message_id=message_id)
        for chat_id, message_id in messages
    ]

    if args.json:
        print(json.dumps([asdict(r) for r in results], indent=2, default=str))
        return 0

    print("Dry-run replay")
    print("--------------")
    print(f"messages_seen={len(results)}")
    print(f"ok={sum(1 for r in results if r.reason == 'ok')}")
    print(f"intents_created={sum(1 for r in results if r.intent_created)}")
    print(f"families_created={sum(1 for r in results if r.family_created)}")
    print(f"mock_executions_created={sum(r.mock_executions_created for r in results)}")

    print("\nResults:")
    for r in results:
        print(
            f"- chat={r.chat_id} msg={r.message_id} provider={r.provider} "
            f"type={r.parsed_type} action={r.decision_action} reason={r.reason} "
            f"intent={r.intent_created} family={r.family_created} mock={r.mock_executions_created}"
        )

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
