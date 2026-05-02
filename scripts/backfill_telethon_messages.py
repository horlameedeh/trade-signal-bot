from __future__ import annotations

import argparse
import asyncio
import os

from dotenv import load_dotenv
from telethon import TelegramClient

from app.services.provider_channels import list_enabled_provider_channels
from app.telegram.telethon_ingestion import persist_telegram_message


def _required_env(name: str) -> str:
    value = os.getenv(name)
    if not value:
        raise RuntimeError(f"{name} is not set")
    return value


async def run(limit_per_channel: int) -> int:
    load_dotenv()

    api_id = int(_required_env("TELEGRAM_API_ID"))
    api_hash = _required_env("TELEGRAM_API_HASH")
    session_name = os.getenv("TELEGRAM_USER_SESSION", "tradebot_ingestion")

    channels = list_enabled_provider_channels(ingestion_mode="telethon")
    if not channels:
        raise RuntimeError("No enabled telegram_provider_channels found")

    client = TelegramClient(
        session_name,
        api_id,
        api_hash,
        connection_retries=None,
        retry_delay=5,
        auto_reconnect=True,
    )

    inserted = 0
    skipped = 0

    async with client:
        for ch in channels:
            print(f"\nChannel: {ch.provider_code} {ch.chat_id} {ch.title}")

            try:
                async for msg in client.iter_messages(ch.chat_id, limit=limit_per_channel):
                    text_value = msg.raw_text or ""
                    if not text_value.strip():
                        continue

                    result = persist_telegram_message(
                        provider_code=ch.provider_code,
                        chat_id=ch.chat_id,
                        message_id=int(msg.id),
                        text_value=text_value,
                        raw_json={
                            "event_id": int(msg.id),
                            "chat_id": ch.chat_id,
                            "provider_code": ch.provider_code,
                            "backfill": True,
                        },
                        dry_run=True,
                    )

                    if result.inserted:
                        inserted += 1
                    else:
                        skipped += 1

                    preview = text_value.replace("\n", " ")[:100]
                    print(f"  msg={msg.id} inserted={result.inserted} preview={preview}")

            except Exception as exc:
                print(f"  ERROR channel={ch.chat_id}: {exc}")

    print(f"\nBackfill complete. inserted={inserted} skipped={skipped}")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--limit-per-channel", type=int, default=5)
    args = parser.parse_args()

    return asyncio.run(run(args.limit_per_channel))


if __name__ == "__main__":
    raise SystemExit(main())