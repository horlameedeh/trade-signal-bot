from __future__ import annotations

from dataclasses import dataclass
from typing import Optional

from sqlalchemy import text

from app.db.session import SessionLocal
from app.parsing.parser import parse_message
from app.services.update_applier import apply_update_to_family
from app.services.update_matcher import MatchResult, match_trade_family_for_update


@dataclass(frozen=True)
class EditHandlingResult:
    chat_id: int
    message_id: int
    provider: Optional[str]
    parsed_type: Optional[str]
    matched_family_id: Optional[str]
    applied: bool
    reason: str


def handle_edited_message(*, chat_id: int, message_id: int) -> EditHandlingResult:
    with SessionLocal() as db:
        row = db.execute(
            text(
                """
                SELECT
                  tm.chat_id,
                  tm.message_id,
                  tm.text,
                  tc.provider_code
                FROM telegram_messages tm
                JOIN telegram_chats tc ON tc.chat_id = tm.chat_id
                WHERE tm.chat_id = :chat_id
                  AND tm.message_id = :message_id
                LIMIT 1
                """
            ),
            {"chat_id": chat_id, "message_id": message_id},
        ).mappings().first()

        if not row:
            return EditHandlingResult(
                chat_id=chat_id,
                message_id=message_id,
                provider=None,
                parsed_type=None,
                matched_family_id=None,
                applied=False,
                reason="message_not_found",
            )

        provider = row["provider_code"]
        parsed = parse_message(provider, row["text"] or "")

        if parsed.message_type.value != "UPDATE":
            return EditHandlingResult(
                chat_id=chat_id,
                message_id=message_id,
                provider=provider,
                parsed_type=parsed.message_type.value,
                matched_family_id=None,
                applied=False,
                reason="edited_message_not_update",
            )

        symbol = parsed.update.symbol if parsed.update else None
        side = None
        direct_family_id = None

        if not symbol:
            latest_family = db.execute(
                text(
                    """
                    SELECT family_id::text AS family_id, symbol_canonical, side
                    FROM trade_families
                    WHERE provider = :provider
                      AND chat_id = :chat_id
                      AND state IN ('PENDING_UPDATE', 'OPEN')
                    ORDER BY
                      CASE
                        WHEN state = 'PENDING_UPDATE' THEN 0
                        WHEN state = 'OPEN' THEN 1
                        ELSE 2
                      END,
                      created_at DESC
                    LIMIT 1
                    """
                ),
                {"provider": provider, "chat_id": chat_id},
            ).mappings().first()

            if latest_family:
                direct_family_id = latest_family["family_id"]
                symbol = latest_family["symbol_canonical"]
                side = latest_family["side"]

        if symbol and not side:
            side = db.execute(
                text(
                    """
                    SELECT side
                    FROM trade_families
                    WHERE provider = :provider
                      AND symbol_canonical = :symbol
                    ORDER BY created_at DESC
                    LIMIT 1
                    """
                ),
                {"provider": provider, "symbol": symbol},
            ).scalar()

    if not side:
        return EditHandlingResult(
            chat_id=chat_id,
            message_id=message_id,
            provider=provider,
            parsed_type=parsed.message_type.value,
            matched_family_id=None,
            applied=False,
            reason="no_matching_side_context",
        )

    if direct_family_id:
        match = MatchResult(
            family_id=direct_family_id,
            requires_selection=False,
            candidates=[],
        )
    else:
        match = match_trade_family_for_update(
            provider=provider,
            symbol=symbol,
            side=side,
        )

    if match.requires_selection:
        return EditHandlingResult(
            chat_id=chat_id,
            message_id=message_id,
            provider=provider,
            parsed_type=parsed.message_type.value,
            matched_family_id=None,
            applied=False,
            reason="multiple_candidates_require_selection",
        )

    if not match.family_id:
        return EditHandlingResult(
            chat_id=chat_id,
            message_id=message_id,
            provider=provider,
            parsed_type=parsed.message_type.value,
            matched_family_id=None,
            applied=False,
            reason="no_matching_family",
        )

    result = apply_update_to_family(
        family_id=match.family_id,
        parsed=parsed,
    )

    return EditHandlingResult(
        chat_id=chat_id,
        message_id=message_id,
        provider=provider,
        parsed_type=parsed.message_type.value,
        matched_family_id=match.family_id,
        applied=result.legs_updated > 0 or result.family_updated,
        reason=result.reason,
    )
