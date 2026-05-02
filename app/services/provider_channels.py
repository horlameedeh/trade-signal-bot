from __future__ import annotations

from dataclasses import dataclass

from sqlalchemy import text

from app.db.session import SessionLocal


@dataclass(frozen=True)
class ProviderChannel:
    provider_code: str
    chat_id: int
    title: str | None
    username: str | None
    channel_type: str
    is_enabled: bool
    ingestion_mode: str


def upsert_provider_channel(
    *,
    provider_code: str,
    chat_id: int,
    title: str | None = None,
    username: str | None = None,
    channel_type: str = "signal",
    is_enabled: bool = True,
    ingestion_mode: str = "telethon",
) -> ProviderChannel:
    with SessionLocal() as db:
        db.execute(
            text(
                """
                INSERT INTO telegram_provider_channels (
                  provider_code, chat_id, title, username, channel_type, is_enabled, ingestion_mode
                )
                VALUES (
                  :provider_code, :chat_id, :title, :username, :channel_type, :is_enabled, :ingestion_mode
                )
                ON CONFLICT (chat_id)
                DO UPDATE SET
                  provider_code = EXCLUDED.provider_code,
                  title = COALESCE(EXCLUDED.title, telegram_provider_channels.title),
                  username = COALESCE(EXCLUDED.username, telegram_provider_channels.username),
                  channel_type = EXCLUDED.channel_type,
                  is_enabled = EXCLUDED.is_enabled,
                  ingestion_mode = EXCLUDED.ingestion_mode,
                  updated_at = now()
                """
            ),
            {
                "provider_code": provider_code,
                "chat_id": chat_id,
                "title": title,
                "username": username,
                "channel_type": channel_type,
                "is_enabled": is_enabled,
                "ingestion_mode": ingestion_mode,
            },
        )
        db.commit()

    return get_provider_channel(chat_id=chat_id)


def get_provider_channel(*, chat_id: int) -> ProviderChannel | None:
    with SessionLocal() as db:
        row = db.execute(
            text(
                """
                SELECT provider_code, chat_id, title, username, channel_type, is_enabled, ingestion_mode
                FROM telegram_provider_channels
                WHERE chat_id = :chat_id
                LIMIT 1
                """
            ),
            {"chat_id": chat_id},
        ).mappings().first()

    if not row:
        return None

    return ProviderChannel(
        provider_code=row["provider_code"],
        chat_id=row["chat_id"],
        title=row["title"],
        username=row["username"],
        channel_type=row["channel_type"],
        is_enabled=row["is_enabled"],
        ingestion_mode=row["ingestion_mode"],
    )


def list_enabled_provider_channels(*, ingestion_mode: str = "telethon") -> list[ProviderChannel]:
    with SessionLocal() as db:
        rows = db.execute(
            text(
                """
                SELECT provider_code, chat_id, title, username, channel_type, is_enabled, ingestion_mode
                FROM telegram_provider_channels
                WHERE is_enabled = true
                  AND ingestion_mode = :ingestion_mode
                ORDER BY provider_code, chat_id
                """
            ),
            {"ingestion_mode": ingestion_mode},
        ).mappings().all()

    return [
        ProviderChannel(
            provider_code=r["provider_code"],
            chat_id=r["chat_id"],
            title=r["title"],
            username=r["username"],
            channel_type=r["channel_type"],
            is_enabled=r["is_enabled"],
            ingestion_mode=r["ingestion_mode"],
        )
        for r in rows
    ]
