from __future__ import annotations

import argparse

from dotenv import load_dotenv
from sqlalchemy import text

from app.db.session import SessionLocal


def main() -> int:
    load_dotenv()

    parser = argparse.ArgumentParser()
    parser.add_argument("--chat-id", type=int, required=True)
    parser.add_argument("--allow-live", choices=["true", "false"], required=True)
    parser.add_argument("--notes", default=None)
    args = parser.parse_args()

    allow_live = args.allow_live == "true"

    with SessionLocal() as db:
        row = db.execute(
            text(
                """
                UPDATE telegram_provider_channels
                SET allow_live_execution = :allow_live,
                    notes = COALESCE(:notes, notes),
                    updated_at = now()
                WHERE chat_id = :chat_id
                RETURNING provider_code, chat_id, title, allow_live_execution
                """
            ),
            {
                "chat_id": args.chat_id,
                "allow_live": allow_live,
                "notes": args.notes,
            },
        ).mappings().first()
        db.commit()

    if not row:
        raise SystemExit(f"No provider channel found for chat_id={args.chat_id}")

    print(dict(row))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())