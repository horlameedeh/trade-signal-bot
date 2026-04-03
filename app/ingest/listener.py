import asyncio
import logging
from typing import Optional

from telethon import events
from telethon.tl.types import Channel, Chat, User

from app.control.alerts import send_control_alert
from app.ingest.chat_id import normalize_chat_id
from app.ingest.filters import is_allowed_chat, is_control_chat, load_allowlist_from_env
from app.ingest.storage import (
    ingest_and_route_new_message,
    upsert_chat,
    upsert_message_edited,
    upsert_message_new_or_seen,
)
from app.ingest.telethon_client import ensure_signed_in, get_user_client


log = logging.getLogger("ingest.listener")


def _safe_chat_type(entity) -> Optional[str]:
    if isinstance(entity, Channel):
        return "channel"
    if isinstance(entity, Chat):
        return "group"
    if isinstance(entity, User):
        return "user"
    return type(entity).__name__.lower() if entity else None


async def run_listener() -> None:
    allow = load_allowlist_from_env()

    client = get_user_client()
    await ensure_signed_in(client)

    @client.on(events.NewMessage())
    async def on_new_message(event: events.NewMessage.Event) -> None:
        try:
            chat = await event.get_chat()
            chat_id = normalize_chat_id(int(event.chat_id))
            username = getattr(chat, "username", None)
            title = getattr(chat, "title", None)
            ctype = _safe_chat_type(chat)

            if not is_allowed_chat(allow, chat_id=chat_id, username=username, title=title):
                return

            control = is_control_chat(allow, chat_id=chat_id, username=username, title=title)

            msg = event.message
            raw = msg.to_dict()
            raw["_meta"] = {
                "event_chat_id_raw": int(event.chat_id),
                "chat_id_normalized": chat_id,
            }

            # IMPORTANT: Never route/control-alert on the Control Chat itself.
            # Control chat messages should be handled by the control bot (Bot API) only.
            if control:
                upsert_chat(
                    chat_id=chat_id,
                    chat_type=ctype,
                    title=title,
                    username=username,
                    is_control=True,
                )
                upsert_message_new_or_seen(
                    chat_id=chat_id,
                    message_id=msg.id,
                    sender_id=msg.sender_id,
                    date=msg.date,
                    message_text=msg.message,
                    raw_json=raw,
                )
                return

            result = ingest_and_route_new_message(
                chat_id=chat_id,
                chat_type=ctype,
                title=title,
                username=username,
                is_control=False,
                message_id=msg.id,
                sender_id=msg.sender_id,
                date=msg.date,
                message_text=msg.message,
                raw_json=raw,
            )

            # Notify control chat on routing alerts (do not block event loop)
            if result.status == "IGNORED_UNKNOWN_CHAT":
                asyncio.get_running_loop().run_in_executor(
                    None,
                    send_control_alert,
                    (
                        f"Unknown chat_id <code>{chat_id}</code>\n"
                        f"Message ignored.\n\n"
                        f"Add mapping:\n"
                        f"<code>!addchannel &lt;provider&gt; {chat_id}</code>"
                    ),
                )

            elif result.status == "IGNORED_NO_ACCOUNT":
                asyncio.get_running_loop().run_in_executor(
                    None,
                    send_control_alert,
                    (
                        f"Provider <b>{result.provider_code}</b> has no active mapped account.\n"
                        f"Message ignored."
                    ),
                )

        except Exception:
            log.exception("Failed to ingest NewMessage")

    @client.on(events.MessageEdited())
    async def on_message_edited(event: events.MessageEdited.Event) -> None:
        try:
            chat = await event.get_chat()
            chat_id = normalize_chat_id(int(event.chat_id))
            username = getattr(chat, "username", None)
            title = getattr(chat, "title", None)
            ctype = _safe_chat_type(chat)

            if not is_allowed_chat(allow, chat_id=chat_id, username=username, title=title):
                return

            control = is_control_chat(allow, chat_id=chat_id, username=username, title=title)

            msg = event.message
            raw = msg.to_dict()
            raw["_meta"] = {
                "event_chat_id_raw": int(event.chat_id),
                "chat_id_normalized": chat_id,
            }

            # Still store edits for control chat, but do not route/alert.
            upsert_chat(
                chat_id=chat_id,
                chat_type=ctype,
                title=title,
                username=username,
                is_control=bool(control),
            )

            # Telethon doesn't always provide a distinct edited timestamp; msg.edit_date is typical.
            upsert_message_edited(
                chat_id=chat_id,
                message_id=msg.id,
                sender_id=msg.sender_id,
                date=msg.date,
                message_text=msg.message,
                edited_at=getattr(msg, "edit_date", None),
                raw_json=raw,
            )

        except Exception:
            log.exception("Failed to ingest MessageEdited")

    log.info("Telegram listener started.")
    await client.run_until_disconnected()


def main() -> None:
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    )
    asyncio.run(run_listener())


if __name__ == "__main__":
    main()
