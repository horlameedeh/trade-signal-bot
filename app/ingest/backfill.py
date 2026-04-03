import argparse
import asyncio
import logging
from datetime import datetime, timedelta, timezone
from typing import Optional, Sequence

from telethon.tl.types import Channel, Chat, User

from app.ingest.filters import is_allowed_chat, is_control_chat, load_allowlist_from_env
from app.ingest.storage import upsert_chat, upsert_message_new_or_seen
from app.ingest.telethon_client import ensure_signed_in, get_user_client


log = logging.getLogger("ingest.backfill")


def _safe_chat_type(entity) -> Optional[str]:
    if isinstance(entity, Channel):
        return "channel"
    if isinstance(entity, Chat):
        return "group"
    if isinstance(entity, User):
        return "user"
    return type(entity).__name__.lower() if entity else None


def _utcnow() -> datetime:
    return datetime.now(timezone.utc)


async def backfill_chat(
    *,
    client,
    allow,
    chat_ref: str,
    limit: Optional[int],
    days: Optional[int],
) -> None:
    entity = await client.get_entity(chat_ref)
    chat_id = getattr(entity, "id", None)

    # Telethon entity ids for channels/groups are often negative in events, but entity.id here is positive.
    # event.chat_id gives the "marked" id (often -100...). For DB consistency, we use event.chat_id in listener.
    # For backfill, Telethon message.chat_id is in Message (often -100...). We’ll read from messages to be safe.

    username = getattr(entity, "username", None)
    title = getattr(entity, "title", None)
    ctype = _safe_chat_type(entity)

    # We'll still enforce allowlist (by username/title) to prevent accidental ingestion.
    # Chat ID enforcement here is tricky due to id normalization; username is the best backfill selector.
    if not is_allowed_chat(
        allow,
        chat_id=int(f"-100{chat_id}") if chat_id else 0,
        username=username,
        title=title,
    ):
        log.warning(
            "Skipping not-allowed chat_ref=%s title=%s username=%s",
            chat_ref,
            title,
            username,
        )
        return

    control = is_control_chat(
        allow,
        chat_id=int(f"-100{chat_id}") if chat_id else 0,
        username=username,
        title=title,
    )

    # Upsert using normalized event-like id where possible:
    normalized_chat_id = int(f"-100{chat_id}") if chat_id else 0

    upsert_chat(
        chat_id=normalized_chat_id,
        chat_type=ctype,
        title=title,
        username=username,
        is_control=control,
    )

    min_date: Optional[datetime] = None
    if days is not None:
        min_date = _utcnow() - timedelta(days=days)

    count = 0
    async for msg in client.iter_messages(entity, limit=limit):
        # msg.chat_id usually aligns with listener chat_id (often -100...)
        chat_id2 = msg.chat_id or normalized_chat_id

        if min_date and msg.date and msg.date < min_date:
            break

        upsert_message_new_or_seen(
            chat_id=chat_id2,
            message_id=msg.id,
            sender_id=msg.sender_id,
            date=msg.date,
            message_text=msg.message,
            raw_json=msg.to_dict(),
        )
        count += 1

    log.info("Backfilled %s messages from %s", count, chat_ref)


async def run_backfill(chats: Sequence[str], limit: Optional[int], days: Optional[int]) -> None:
    allow = load_allowlist_from_env()
    client = get_user_client()
    await ensure_signed_in(client)

    for chat_ref in chats:
        await backfill_chat(client=client, allow=allow, chat_ref=chat_ref, limit=limit, days=days)

    await client.disconnect()


def main() -> None:
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    )

    p = argparse.ArgumentParser(
        description="Backfill Telegram messages into telegram_messages (idempotent)."
    )
    p.add_argument(
        "--chat",
        action="append",
        required=True,
        help="Chat reference: @username, invite link, or numeric id.",
    )
    p.add_argument(
        "--limit",
        type=int,
        default=None,
        help="Max messages per chat (most recent first).",
    )
    p.add_argument(
        "--days",
        type=int,
        default=None,
        help="Backfill until now()-days (stops when older).",
    )
    args = p.parse_args()

    asyncio.run(run_backfill(chats=args.chat, limit=args.limit, days=args.days))


if __name__ == "__main__":
    main()
