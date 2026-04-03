from __future__ import annotations

import os
import time
from datetime import datetime, timezone

from sqlalchemy import text

from app.db.session import SessionLocal
from app.ingest.storage import ingest_and_route_new_message


FRED_CHAT_ID = -1001239815745  # mapped in your showrouting output


def _now():
    return datetime.now(timezone.utc)


def _print_last_decisions(chat_id: int, limit: int = 5) -> None:
    with SessionLocal() as db:
        rows = db.execute(
            text(
                """
                SELECT decision, provider_code, broker_account_id::text AS broker_account_id, chat_id, message_id, created_at
                FROM routing_decisions
                WHERE chat_id = :chat_id
                ORDER BY created_at DESC
                LIMIT :limit
                """
            ),
            {"chat_id": chat_id, "limit": limit},
        ).mappings().all()

    print(f"Last {limit} routing_decisions for chat_id={chat_id}:")
    for r in rows:
        print(dict(r))


def _set_provider_mapping(chat_id: int, provider_code: str | None) -> None:
    with SessionLocal() as db:
        db.execute(
            text("UPDATE telegram_chats SET provider_code = :p WHERE chat_id = :c"),
            {"p": provider_code, "c": chat_id},
        )
        db.commit()


def _set_provider_route_active(provider_code: str, active: bool) -> None:
    with SessionLocal() as db:
        db.execute(
            text("UPDATE provider_account_routes SET is_active = :a WHERE provider_code = :p"),
            {"a": active, "p": provider_code},
        )
        db.commit()


def _get_provider_code(chat_id: int) -> str | None:
    with SessionLocal() as db:
        r = db.execute(
            text("SELECT provider_code FROM telegram_chats WHERE chat_id = :c"),
            {"c": chat_id},
        ).scalar()
    return r


def main() -> None:
    # Use a unique message_id per run
    msg_id = int(time.time())
    sent_at = _now()

    # Ensure chat exists
    with SessionLocal() as db:
        exists = db.execute(
            text("SELECT 1 FROM telegram_chats WHERE chat_id = :c"),
            {"c": FRED_CHAT_ID},
        ).scalar()
    if not exists:
        raise SystemExit(f"telegram_chats missing row for {FRED_CHAT_ID}. Add it first (or via !addchannel).")

    provider = _get_provider_code(FRED_CHAT_ID)
    if not provider:
        raise SystemExit(f"Chat {FRED_CHAT_ID} has no provider_code set; set it to 'fredtrading' first.")

    print("=== Test 3 (Happy path): should ROUTE ===")
    result = ingest_and_route_new_message(
        chat_id=FRED_CHAT_ID,
        chat_type="channel",
        title="SIMULATED: Fredtrading",
        username=None,
        is_control=False,
        message_id=msg_id,
        sender_id=123456,
        date=sent_at,
        message_text="SIMULATED MESSAGE: happy path",
        raw_json={"simulated": True, "case": "happy_path"},
    )
    print("RouteResult:", result)
    _print_last_decisions(FRED_CHAT_ID)

    print("\n=== Test 1 (Unknown chat mapping): should IGNORED_UNKNOWN_CHAT ===")
    # Temporarily remove provider_code mapping
    _set_provider_mapping(FRED_CHAT_ID, None)

    msg_id2 = msg_id + 1
    result2 = ingest_and_route_new_message(
        chat_id=FRED_CHAT_ID,
        chat_type="channel",
        title="SIMULATED: Fredtrading",
        username=None,
        is_control=False,
        message_id=msg_id2,
        sender_id=123456,
        date=_now(),
        message_text="SIMULATED MESSAGE: unknown mapping",
        raw_json={"simulated": True, "case": "unknown_mapping"},
    )
    print("RouteResult:", result2)
    _print_last_decisions(FRED_CHAT_ID)

    # Restore mapping
    _set_provider_mapping(FRED_CHAT_ID, provider)

    print("\n=== Test 2 (No active route): should IGNORED_NO_ACCOUNT ===")
    # Temporarily disable route for provider
    _set_provider_route_active(provider, False)

    msg_id3 = msg_id + 2
    result3 = ingest_and_route_new_message(
        chat_id=FRED_CHAT_ID,
        chat_type="channel",
        title="SIMULATED: Fredtrading",
        username=None,
        is_control=False,
        message_id=msg_id3,
        sender_id=123456,
        date=_now(),
        message_text="SIMULATED MESSAGE: no active route",
        raw_json={"simulated": True, "case": "no_active_route"},
    )
    print("RouteResult:", result3)
    _print_last_decisions(FRED_CHAT_ID)

    # Restore route
    _set_provider_route_active(provider, True)

    print("\n=== Test 4 (Idempotency): duplicate message_id should be DUPLICATE and no extra decision ===")
    result4 = ingest_and_route_new_message(
        chat_id=FRED_CHAT_ID,
        chat_type="channel",
        title="SIMULATED: Fredtrading",
        username=None,
        is_control=False,
        message_id=msg_id,  # same as first happy-path message_id
        sender_id=123456,
        date=_now(),
        message_text="SIMULATED MESSAGE: duplicate",
        raw_json={"simulated": True, "case": "duplicate"},
    )
    print("RouteResult:", result4)
    _print_last_decisions(FRED_CHAT_ID)

    print("\n✅ Simulation tests complete.")


if __name__ == "__main__":
    main()
