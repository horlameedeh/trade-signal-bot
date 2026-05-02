from __future__ import annotations

import asyncio
import os
from dataclasses import dataclass

from dotenv import load_dotenv
from sqlalchemy import text
from telethon import TelegramClient, events

from app.db.session import SessionLocal
from app.services.provider_channels import list_enabled_provider_channels
from app.services.alerts import alert_execution_failure


@dataclass(frozen=True)
class IngestedTelegramMessage:
    provider_code: str
    chat_id: int
    message_id: int
    text: str
    dry_run: bool
    inserted: bool


def _bool_env(name: str, default: bool = False) -> bool:
    raw = os.getenv(name)
    if raw is None:
        return default
    return raw.strip().lower() in {"1", "true", "yes", "y", "on"}


def _required_env(name: str) -> str:
    value = os.getenv(name)
    if not value:
        raise RuntimeError(f"{name} is not set")
    return value


def persist_telegram_message(
    *,
    provider_code: str,
    chat_id: int,
    message_id: int,
    text_value: str,
    raw_json: dict | None = None,
    dry_run: bool = True,
) -> IngestedTelegramMessage:
    """
    Persists raw Telegram message safely.
    Dry-run still stores the message but tags raw_json.dry_run=true.
    Dedupes by chat_id/message_id if a unique constraint exists, otherwise by explicit lookup.
    """
    raw_json = raw_json or {}
    raw_json = {**raw_json, "dry_run": dry_run, "source": "telethon_ingestion"}

    with SessionLocal() as db:
        exists = db.execute(
            text(
                """
                SELECT 1
                FROM telegram_messages
                WHERE chat_id = :chat_id
                  AND message_id = :message_id
                LIMIT 1
                """
            ),
            {"chat_id": chat_id, "message_id": message_id},
        ).scalar()

        if exists:
            return IngestedTelegramMessage(
                provider_code=provider_code,
                chat_id=chat_id,
                message_id=message_id,
                text=text_value,
                dry_run=dry_run,
                inserted=False,
            )

        db.execute(
            text(
                """
                INSERT INTO telegram_chats (chat_id, title, username, is_active)
                VALUES (:chat_id, NULL, NULL, true)
                ON CONFLICT DO NOTHING
                """
            ),
            {"chat_id": chat_id},
        )

        db.execute(
            text(
                """
                INSERT INTO telegram_messages (
                  chat_id, message_id, text, raw_json
                )
                VALUES (
                  :chat_id, :message_id, :text_value, CAST(:raw_json AS jsonb)
                )
                """
            ),
            {
                "chat_id": chat_id,
                "message_id": message_id,
                "text_value": text_value,
                "raw_json": __import__("json").dumps(raw_json),
            },
        )
        db.commit()

    return IngestedTelegramMessage(
        provider_code=provider_code,
        chat_id=chat_id,
        message_id=message_id,
        text=text_value,
        dry_run=dry_run,
        inserted=True,
    )


async def run_telethon_ingestion() -> None:
    load_dotenv()

    enabled = _bool_env("TELEGRAM_INGESTION_ENABLED", False)
    dry_run = _bool_env("TELEGRAM_INGESTION_DRY_RUN", True)

    if not enabled:
        print("Telegram ingestion disabled: TELEGRAM_INGESTION_ENABLED=false", flush=True)
        return

    api_id = int(_required_env("TELEGRAM_API_ID"))
    api_hash = _required_env("TELEGRAM_API_HASH")
    session_name = os.getenv("TELEGRAM_USER_SESSION", "tradebot_ingestion")

    channels = list_enabled_provider_channels(ingestion_mode="telethon")
    if not channels:
        raise RuntimeError("No enabled telegram_provider_channels found")

    chat_to_provider = {c.chat_id: c.provider_code for c in channels}
    chat_to_live_allowed = {c.chat_id: bool(getattr(c, "allow_live_execution", False)) for c in channels}
    chat_ids = list(chat_to_provider.keys())

    print(f"Starting Telethon ingestion. dry_run={dry_run} channels={len(chat_ids)}", flush=True)

    client = TelegramClient(
        session_name,
        api_id,
        api_hash,
        connection_retries=None,
        retry_delay=5,
        auto_reconnect=True,
    )

    @client.on(events.NewMessage(chats=chat_ids))
    async def handler(event):
        try:
            chat_id = int(event.chat_id)
            provider_code = chat_to_provider.get(chat_id)
            if not provider_code:
                print(f"Ignored unknown chat_id={chat_id}", flush=True)
                return

            text_value = event.raw_text or ""
            if not text_value.strip():
                print(f"Ignored empty message chat_id={chat_id} message_id={event.id}", flush=True)
                return

            channel_live_allowed = chat_to_live_allowed.get(chat_id, False)
            effective_dry_run = dry_run or not channel_live_allowed

            result = persist_telegram_message(
                provider_code=provider_code,
                chat_id=chat_id,
                message_id=int(event.id),
                text_value=text_value,
                raw_json={
                    "event_id": int(event.id),
                    "chat_id": chat_id,
                    "provider_code": provider_code,
                    "channel_live_allowed": channel_live_allowed,
                    "global_dry_run": dry_run,
                },
                dry_run=effective_dry_run,
            )

            print(
                f"ingested provider={provider_code} chat_id={chat_id} "
                f"message_id={event.id} inserted={result.inserted} dry_run={result.dry_run}",
                flush=True,
            )

        except Exception as exc:
            alert_execution_failure(
                message=f"Telegram ingestion failed: {exc}",
                data={"component": "telethon_ingestion"},
            )
            print(f"ERROR telegram ingestion handler: {exc}", flush=True)

    await client.start()
    print("Telethon ingestion connected.", flush=True)
    await client.run_until_disconnected()


def main() -> int:
    asyncio.run(run_telethon_ingestion())
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
