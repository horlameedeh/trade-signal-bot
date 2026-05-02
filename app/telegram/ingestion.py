from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Any

import yaml
from sqlalchemy import text

from app.db.session import SessionLocal
from app.services.alerts import alert_execution_failure


DEFAULT_SIGNAL_CHANNELS_PATH = Path("config/signal_channels.yaml")


@dataclass(frozen=True)
class SignalChannel:
    provider: str
    chat_id: int
    label: str | None
    enabled: bool


@dataclass(frozen=True)
class IngestedMessageResult:
    chat_id: int
    message_id: int
    provider: str
    inserted: bool
    duplicate: bool
    text_len: int


def load_signal_channels(path: Path | None = None) -> tuple[bool, bool, list[SignalChannel]]:
    if path is None:
        path = DEFAULT_SIGNAL_CHANNELS_PATH

    cfg = yaml.safe_load(path.read_text(encoding="utf-8")) or {}

    enabled = bool(cfg.get("enabled", True))
    dry_run = bool(cfg.get("dry_run", True))

    channels = []
    for item in cfg.get("channels") or []:
        if not item.get("enabled", True):
            continue

        channels.append(
            SignalChannel(
                provider=str(item["provider"]),
                chat_id=int(item["chat_id"]),
                label=item.get("label"),
                enabled=True,
            )
        )

    return enabled, dry_run, channels


def ensure_telegram_chat(provider: str, chat_id: int) -> None:
    with SessionLocal() as db:
        db.execute(
            text(
                """
                INSERT INTO telegram_chats (chat_id, provider_code)
                VALUES (:chat_id, CAST(:provider AS provider_code))
                ON CONFLICT (chat_id)
                DO UPDATE SET provider_code = CAST(:provider AS provider_code)
                """
            ),
            {"chat_id": chat_id, "provider": provider},
        )
        db.commit()


def persist_telegram_message(
    *,
    provider: str,
    chat_id: int,
    message_id: int,
    text_body: str,
    raw_json: dict[str, Any] | None = None,
) -> IngestedMessageResult:
    ensure_telegram_chat(provider=provider, chat_id=chat_id)

    raw_json = raw_json or {}

    with SessionLocal() as db:
        existing = db.execute(
            text(
                """
                SELECT msg_pk
                FROM telegram_messages
                WHERE chat_id = :chat_id
                  AND message_id = :message_id
                LIMIT 1
                """
            ),
            {"chat_id": chat_id, "message_id": message_id},
        ).scalar()

        if existing:
            return IngestedMessageResult(
                chat_id=chat_id,
                message_id=message_id,
                provider=provider,
                inserted=False,
                duplicate=True,
                text_len=len(text_body or ""),
            )

        db.execute(
            text(
                """
                INSERT INTO telegram_messages (
                  chat_id,
                  message_id,
                  text,
                  raw_json
                )
                VALUES (
                  :chat_id,
                  :message_id,
                  :text_body,
                  CAST(:raw_json AS jsonb)
                )
                """
            ),
            {
                "chat_id": chat_id,
                "message_id": message_id,
                "text_body": text_body,
                "raw_json": raw_json,
            },
        )
        db.commit()

    return IngestedMessageResult(
        chat_id=chat_id,
        message_id=message_id,
        provider=provider,
        inserted=True,
        duplicate=False,
        text_len=len(text_body or ""),
    )


def alert_ingestion_failure(*, provider: str | None, chat_id: int | None, error: str) -> None:
    alert_execution_failure(
        message=f"Telegram ingestion failed: {error}",
        broker=None,
        platform=None,
        data={
            "component": "telegram_ingestion",
            "provider": provider,
            "chat_id": chat_id,
        },
    )
