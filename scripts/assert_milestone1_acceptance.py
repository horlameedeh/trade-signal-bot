"""
Milestone 1 Acceptance Validator

Checks:
  - DB connectivity
  - control_chat_id saved in app_settings
  - ENV control chat matches DB
  - At least one control_action recorded
  - Listener ingested at least one telegram_message recently

Usage:
  PYTHONPATH=. python scripts/assert_milestone1_acceptance.py

Exit codes:
  0 -> PASS
  2 -> FAIL
"""

import os
from datetime import datetime, timedelta, timezone
from sqlalchemy import text
from app.db.session import SessionLocal


FAIL = False


def fail(msg: str):
    global FAIL
    print(f"❌ {msg}")
    FAIL = True


def ok(msg: str):
    print(f"✅ {msg}")


def get_env_control_chat():
    raw = os.getenv("TELEGRAM_CONTROL_CHAT_IDS")
    if not raw:
        return None
    try:
        return int(raw.split(",")[0].strip())
    except Exception:
        return None


def main():
    print("\n🔍 Running Milestone 1 Acceptance Checks...\n")

    try:
        with SessionLocal() as db:

            # 1. DB health
            db.execute(text("select 1")).fetchone()
            ok("Database reachable")

            # 2. control_chat_id exists
            row = db.execute(
                text("select value from app_settings where key='control_chat_id'")
            ).fetchone()

            if not row:
                fail("control_chat_id not set in app_settings")
                control_id = None
            else:
                control_id = int(row[0])
                ok(f"control_chat_id set in DB: {control_id}")

            # 3. ENV matches DB
            env_id = get_env_control_chat()
            if control_id and env_id:
                if control_id == env_id:
                    ok("ENV TELEGRAM_CONTROL_CHAT_IDS matches DB")
                else:
                    fail("ENV TELEGRAM_CONTROL_CHAT_IDS does NOT match DB")
            else:
                fail("Missing ENV TELEGRAM_CONTROL_CHAT_IDS or DB control_chat_id")

            # 4. At least one control action exists
            action_count = db.execute(
                text("select count(*) from control_actions")
            ).scalar_one()

            if action_count > 0:
                ok(f"control_actions recorded: {action_count}")
            else:
                fail("No control_actions found (button callback missing?)")

            # 5. Listener ingestion recent
            last_ingested = db.execute(
                text("select max(created_at) from telegram_messages")
            ).scalar_one()

            if not last_ingested:
                fail("No telegram_messages found (listener not running?)")
            else:
                ok(f"Last telegram message ingested at {last_ingested}")

                # Optional recency check (within 30 minutes)
                now = datetime.now(timezone.utc)
                if last_ingested < now - timedelta(minutes=30):
                    fail("Listener has not ingested messages in last 30 minutes")
                else:
                    ok("Listener appears active (recent ingestion)")

    except Exception as e:
        fail(f"Unexpected error: {repr(e)}")

    print("\n--------------------------------------------")

    if FAIL:
        print("🚨 MILESTONE 1 ACCEPTANCE: FAIL")
        raise SystemExit(2)
    else:
        print("🎉 MILESTONE 1 ACCEPTANCE: PASS")
        raise SystemExit(0)


if __name__ == "__main__":
    main()
