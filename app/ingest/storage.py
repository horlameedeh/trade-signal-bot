from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
from typing import Any, Optional

from sqlalchemy import text

from app.db.session import SessionLocal


@dataclass(frozen=True)
class RouteResult:
    status: str  # "ROUTED" | "IGNORED_UNKNOWN_CHAT" | "IGNORED_NO_ACCOUNT" | "DUPLICATE"
    provider_code: str | None
    broker_account_id: str | None  # UUID as string
    reason: str | None
    inserted_message: bool


def upsert_chat(
    *,
    chat_id: int,
    chat_type: Optional[str],
    title: Optional[str],
    username: Optional[str],
    is_control: bool,
) -> None:
    with SessionLocal() as db:
        stmt = text(
            """
            INSERT INTO telegram_chats (chat_id, title, username, is_control_chat, updated_at)
            VALUES (:chat_id, :title, :username, :is_control_chat, now())
            ON CONFLICT (chat_id) DO UPDATE
              SET title = EXCLUDED.title,
                  username = EXCLUDED.username,
                  is_control_chat = EXCLUDED.is_control_chat,
                  updated_at = now();
            """
        )
        db.execute(
            stmt,
            {
                "chat_id": chat_id,
                "title": title,
                "username": username,
                "is_control_chat": is_control,
            },
        )
        db.commit()


def upsert_message_new_or_seen(
    *,
    chat_id: int,
    message_id: int,
    sender_id: Optional[int],
    date: Optional[datetime],
    message_text: Optional[str],
    raw_json: Any,
) -> None:
    """Idempotent insert: on conflict DO NOTHING."""
    with SessionLocal() as db:
        stmt = text(
            """
            INSERT INTO telegram_messages (
              chat_id, message_id, sender_id, sent_at, text, raw_json, is_edited, edited_at
            )
            VALUES (
              :chat_id, :message_id, :sender_id, :sent_at, :text, CAST(:raw_json AS jsonb), FALSE, NULL
            )
            ON CONFLICT (chat_id, message_id) DO NOTHING;
            """
        )
        db.execute(
            stmt,
            {
                "chat_id": chat_id,
                "message_id": message_id,
                "sender_id": sender_id,
                "sent_at": date,
                "text": message_text,
                "raw_json": _ensure_json(raw_json),
            },
        )
        db.commit()


def upsert_message_edited(
    *,
    chat_id: int,
    message_id: int,
    sender_id: Optional[int],
    date: Optional[datetime],
    message_text: Optional[str],
    edited_at: Optional[datetime],
    raw_json: Any,
) -> None:
    """Idempotent update: on conflict DO UPDATE with latest text + raw_json."""
    with SessionLocal() as db:
        stmt = text(
            """
            INSERT INTO telegram_messages (
              chat_id, message_id, sender_id, sent_at, text, raw_json, is_edited, edited_at
            )
            VALUES (
              :chat_id, :message_id, :sender_id, :sent_at, :text, CAST(:raw_json AS jsonb), TRUE, :edited_at
            )
            ON CONFLICT (chat_id, message_id) DO UPDATE
              SET sender_id = EXCLUDED.sender_id,
                  sent_at = COALESCE(EXCLUDED.sent_at, telegram_messages.sent_at),
                  text = EXCLUDED.text,
                  raw_json = EXCLUDED.raw_json,
                  is_edited = TRUE,
                  edited_at = COALESCE(EXCLUDED.edited_at, telegram_messages.edited_at);
            """
        )
        db.execute(
            stmt,
            {
                "chat_id": chat_id,
                "message_id": message_id,
                "sender_id": sender_id,
                "sent_at": date,
                "text": message_text,
                "edited_at": edited_at,
                "raw_json": _ensure_json(raw_json),
            },
        )
        db.commit()


def ingest_and_route_new_message(
    *,
    chat_id: int,
    chat_type: Optional[str],
    title: Optional[str],
    username: Optional[str],
    is_control: bool,
    message_id: int,
    sender_id: Optional[int],
    date: Optional[datetime],
    message_text: Optional[str],
    raw_json: Any,
) -> RouteResult:
    """Atomic ingest + deterministic routing decision.

    - Inserts telegram_messages idempotently.
    - Logs routing_decisions only if a message row was newly inserted.
    - routing_decisions is protected by UNIQUE(chat_id, message_id), so decision inserts are idempotent too.
    - Populates routing_decisions.telegram_msg_pk (UUID FK to telegram_messages.msg_pk) for traceability.

    Returns a RouteResult so the caller can decide whether to alert the Control Chat.
    """

    with SessionLocal() as db:
        # 1) upsert chat
        db.execute(
            text(
                """
                INSERT INTO telegram_chats (chat_id, title, username, is_control_chat, updated_at)
                VALUES (:chat_id, :title, :username, :is_control_chat, now())
                ON CONFLICT (chat_id) DO UPDATE
                  SET title = EXCLUDED.title,
                      username = EXCLUDED.username,
                      is_control_chat = EXCLUDED.is_control_chat,
                      updated_at = now();
                """
            ),
            {
                "chat_id": chat_id,
                "title": title,
                "username": username,
                "is_control_chat": is_control,
            },
        )

        # 2) insert message idempotently and detect whether we inserted
        inserted = (
            db.execute(
                text(
                    """
                    INSERT INTO telegram_messages (
                      chat_id, message_id, sender_id, sent_at, text, raw_json, is_edited, edited_at
                    )
                    VALUES (
                      :chat_id, :message_id, :sender_id, :sent_at, :text, CAST(:raw_json AS jsonb), FALSE, NULL
                    )
                    ON CONFLICT (chat_id, message_id) DO NOTHING
                    RETURNING 1;
                    """
                ),
                {
                    "chat_id": chat_id,
                    "message_id": message_id,
                    "sender_id": sender_id,
                    "sent_at": date,
                    "text": message_text,
                    "raw_json": _ensure_json(raw_json),
                },
            ).scalar()
        )

        inserted_message = bool(inserted)

        # If we didn't insert (duplicate), do not spam routing_decisions.
        if not inserted_message:
            db.commit()
            return RouteResult(
                status="DUPLICATE",
                provider_code=None,
                broker_account_id=None,
                reason="telegram_messages already contained (chat_id, message_id)",
                inserted_message=False,
            )

        # 2b) fetch the UUID PK (msg_pk) for traceability (FK on routing_decisions.telegram_msg_pk)
        telegram_msg_pk = (
            db.execute(
                text(
                    """
                    SELECT msg_pk::text
                    FROM telegram_messages
                    WHERE chat_id = :chat_id AND message_id = :message_id
                    """
                ),
                {"chat_id": chat_id, "message_id": message_id},
            ).scalar()
        )

        # 3) determine provider_code from telegram_chats
        provider_row = (
            db.execute(
                text("SELECT provider_code FROM telegram_chats WHERE chat_id = :chat_id"),
                {"chat_id": chat_id},
            )
            .mappings()
            .first()
        )
        provider_code = provider_row["provider_code"] if provider_row else None

        if not provider_code:
            decision = "IGNORED_UNKNOWN_CHAT"
            reason = "No chat_id → provider mapping"
            raw_meta = {"message_id": message_id}

            db.execute(
                text(
                    """
                    INSERT INTO routing_decisions (
                      telegram_message_id,
                      telegram_msg_pk,
                      chat_id,
                      message_id,
                      provider_code,
                      broker_account_id,
                      decision,
                      reason,
                      message_ts,
                      raw_meta
                    )
                    VALUES (
                      :telegram_message_id,
                      :telegram_msg_pk,
                      :chat_id,
                      :message_id,
                      :provider_code,
                      :broker_account_id,
                      :decision,
                      :reason,
                      :message_ts,
                      CAST(:raw_meta AS jsonb)
                    )
                    ON CONFLICT (chat_id, message_id) DO NOTHING;
                    """
                ),
                {
                    "telegram_message_id": None,
                    "telegram_msg_pk": telegram_msg_pk,
                    "chat_id": chat_id,
                    "message_id": message_id,
                    "provider_code": None,
                    "broker_account_id": None,
                    "decision": decision,
                    "reason": reason,
                    "message_ts": date,
                    "raw_meta": _ensure_json(raw_meta or {}),
                },
            )
            db.commit()
            return RouteResult(
                status="IGNORED_UNKNOWN_CHAT",
                provider_code=None,
                broker_account_id=None,
                reason=reason,
                inserted_message=True,
            )

        # 3b) get active account for provider
        route = (
            db.execute(
                text(
                    """
                    SELECT par.broker_account_id::text AS broker_account_id
                    FROM provider_account_routes par
                    WHERE par.provider_code = :provider_code AND par.is_active = true
                    LIMIT 1;
                    """
                ),
                {"provider_code": provider_code},
            )
            .mappings()
            .first()
        )

        if not route:
            decision = "IGNORED_NO_ACCOUNT"
            reason = "Provider has no active mapped account"
            raw_meta = {"message_id": message_id}

            db.execute(
                text(
                    """
                    INSERT INTO routing_decisions (
                      telegram_message_id,
                      telegram_msg_pk,
                      chat_id,
                      message_id,
                      provider_code,
                      broker_account_id,
                      decision,
                      reason,
                      message_ts,
                      raw_meta
                    )
                    VALUES (
                      :telegram_message_id,
                      :telegram_msg_pk,
                      :chat_id,
                      :message_id,
                      :provider_code,
                      :broker_account_id,
                      :decision,
                      :reason,
                      :message_ts,
                      CAST(:raw_meta AS jsonb)
                    )
                    ON CONFLICT (chat_id, message_id) DO NOTHING;
                    """
                ),
                {
                    "telegram_message_id": None,
                    "telegram_msg_pk": telegram_msg_pk,
                    "chat_id": chat_id,
                    "message_id": message_id,
                    "provider_code": provider_code,
                    "broker_account_id": None,
                    "decision": decision,
                    "reason": reason,
                    "message_ts": date,
                    "raw_meta": _ensure_json(raw_meta or {}),
                },
            )
            db.commit()
            return RouteResult(
                status="IGNORED_NO_ACCOUNT",
                provider_code=provider_code,
                broker_account_id=None,
                reason=reason,
                inserted_message=True,
            )

        broker_account_id = route["broker_account_id"]

        decision = "ROUTED"
        reason = None
        raw_meta = {"message_id": message_id}

        db.execute(
            text(
                """
                INSERT INTO routing_decisions (
                  telegram_message_id,
                  telegram_msg_pk,
                  chat_id,
                  message_id,
                  provider_code,
                  broker_account_id,
                  decision,
                  reason,
                  message_ts,
                  raw_meta
                )
                VALUES (
                  :telegram_message_id,
                  :telegram_msg_pk,
                  :chat_id,
                  :message_id,
                  :provider_code,
                  :broker_account_id,
                  :decision,
                  :reason,
                  :message_ts,
                  CAST(:raw_meta AS jsonb)
                )
                ON CONFLICT (chat_id, message_id) DO NOTHING;
                """
            ),
            {
                "telegram_message_id": None,
                "telegram_msg_pk": telegram_msg_pk,
                "chat_id": chat_id,
                "message_id": message_id,
                "provider_code": provider_code,
                "broker_account_id": broker_account_id,
                "decision": decision,
                "reason": reason,
                "message_ts": date,
                "raw_meta": _ensure_json(raw_meta or {}),
            },
        )

        db.commit()
        return RouteResult(
            status="ROUTED",
            provider_code=provider_code,
            broker_account_id=broker_account_id,
            reason=None,
            inserted_message=True,
        )


def _ensure_json(raw: Any) -> str:
    import json

    if isinstance(raw, str):
        return raw
    return json.dumps(raw, default=str)
