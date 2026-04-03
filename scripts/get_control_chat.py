"""
Print the linked control chat id from app_settings and compare with .env.

Reads:
  - Postgres: app_settings.key = 'control_chat_id'
  - .env: TELEGRAM_CONTROL_CHAT_IDS (first id)

Usage:
  PYTHONPATH=. python scripts/get_control_chat.py
Exit codes:
  0 -> OK / info printed
  2 -> mismatch detected (DB vs .env)
"""
from __future__ import annotations

import os
from typing import Optional

from sqlalchemy import text
from app.db.session import SessionLocal


def first_int_from_csv(v: Optional[str]) -> Optional[int]:
    if not v:
        return None
    parts = [p.strip() for p in v.split(",") if p.strip()]
    if not parts:
        return None
    try:
        return int(parts[0])
    except ValueError:
        return None


def get_db_control_chat_id() -> Optional[int]:
    with SessionLocal() as db:
        row = db.execute(
            text("select value from app_settings where key='control_chat_id'")
        ).fetchone()
    if not row:
        return None
    try:
        return int(row[0])
    except ValueError:
        return None


def main() -> None:
    env_val = os.getenv("TELEGRAM_CONTROL_CHAT_IDS") or os.getenv("TELEGRAM_CONTROL_CHAT_ID")
    env_id = first_int_from_csv(env_val)
    db_id = get_db_control_chat_id()

    print("Control chat binding:")
    print(f"  DB  app_settings.control_chat_id: {db_id}")
    print(f"  ENV TELEGRAM_CONTROL_CHAT_IDS:    {env_id}")

    if db_id is None:
        print("\n⚠️ DB control chat not set. In Telegram control chat, type: !setcontrol")
        return

    if env_id is None:
        print("\n⚠️ ENV control chat not set. Add TELEGRAM_CONTROL_CHAT_IDS to .env.")
        return

    if db_id != env_id:
        print("\n❌ MISMATCH: DB control_chat_id != ENV TELEGRAM_CONTROL_CHAT_IDS")
        print("Fix options:")
        print("  - Prefer DB: update .env to match DB")
        print("  - Prefer ENV: type !setcontrol in the intended control chat again")
        raise SystemExit(2)

    print("\n✅ OK: DB and ENV control chat IDs match.")


if __name__ == "__main__":
    main()
