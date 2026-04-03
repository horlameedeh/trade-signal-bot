from __future__ import annotations

import logging
from dataclasses import dataclass
from typing import Optional

from sqlalchemy import text

from app.db.session import SessionLocal
from app.parsing.models import MessageType, ParsedSignal
from app.parsing.parser import parse_message
from app.parsing.persist import persist_parsed_signal


log = logging.getLogger("parsing.service")


@dataclass(frozen=True)
class ParseServiceResult:
    msg_pk: str
    provider_code: Optional[str]
    broker_account_id: Optional[str]
    parsed: Optional[ParsedSignal]
    persisted: bool
    skipped_reason: Optional[str] = None


def _load_message_row(db, msg_pk: str):
    row = db.execute(
        text(
            """
            SELECT tm.msg_pk::text AS msg_pk,
                   tm.chat_id,
                   tm.message_id,
                   tm.text,
                   tc.provider_code
            FROM telegram_messages tm
            JOIN telegram_chats tc ON tc.chat_id = tm.chat_id
            WHERE tm.msg_pk = CAST(:msg_pk AS uuid)
            """
        ),
        {"msg_pk": msg_pk},
    ).mappings().first()
    return row


def _load_active_route(db, provider_code: str) -> Optional[str]:
    row = db.execute(
        text(
            """
            SELECT broker_account_id::text AS broker_account_id
            FROM provider_account_routes
            WHERE provider_code = :provider_code
              AND is_active = true
            LIMIT 1
            """
        ),
        {"provider_code": provider_code},
    ).mappings().first()
    return row["broker_account_id"] if row else None


def parse_and_persist_message(msg_pk: str) -> ParseServiceResult:
    with SessionLocal() as db:
        row = _load_message_row(db, msg_pk)
        if not row:
            return ParseServiceResult(
                msg_pk=msg_pk,
                provider_code=None,
                broker_account_id=None,
                parsed=None,
                persisted=False,
                skipped_reason="telegram_message_not_found",
            )

        provider_code = row["provider_code"]
        if not provider_code:
            return ParseServiceResult(
                msg_pk=msg_pk,
                provider_code=None,
                broker_account_id=None,
                parsed=None,
                persisted=False,
                skipped_reason="no_provider_code",
            )

        text_value = row["text"] or ""
        parsed = parse_message(provider_code, text_value)
        log.info(
            "Parsed signal",
            extra={
                "provider": provider_code,
                "symbol": parsed.symbol,
                "confidence": parsed.confidence,
                "type": parsed.message_type.value,
            },
        )

        # INFO / UNKNOWN are classified but not persisted to intents/updates
        if parsed.message_type not in {MessageType.NEW_TRADE, MessageType.UPDATE}:
            return ParseServiceResult(
                msg_pk=msg_pk,
                provider_code=provider_code,
                broker_account_id=None,
                parsed=parsed,
                persisted=False,
                skipped_reason=f"message_type_{parsed.message_type.value.lower()}",
            )

        broker_account_id = _load_active_route(db, provider_code)

    # persist in separate call/session for simplicity and reuse
    persist_parsed_signal(
        source_msg_pk=msg_pk,
        provider_code=provider_code,
        broker_account_id=broker_account_id,
        parsed=parsed,
    )

    return ParseServiceResult(
        msg_pk=msg_pk,
        provider_code=provider_code,
        broker_account_id=broker_account_id,
        parsed=parsed,
        persisted=True,
        skipped_reason=None,
    )
