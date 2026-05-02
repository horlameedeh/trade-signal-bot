from __future__ import annotations

from dataclasses import dataclass

from sqlalchemy import text

from app.db.session import SessionLocal


@dataclass(frozen=True)
class IngestionRouteResult:
    messages_seen: int
    routed: int
    ignored: int
    failed: int


def _looks_like_trade_signal(text_value: str) -> bool:
    text_upper = (text_value or "").upper()

    has_symbol = any(s in text_upper for s in ["XAUUSD", "BTCUSD", "BTCUSDT", "US30", "NAS100"])
    has_side = any(s in text_upper for s in ["BUY", "SELL", "LONG", "SHORT"])
    has_risk = "SL" in text_upper or "STOP" in text_upper

    return has_symbol and has_side and has_risk


def _mark_message_routed(*, msg_pk: str, status: str, reason: str | None = None) -> None:
    with SessionLocal() as db:
        db.execute(
            text(
                """
                UPDATE telegram_messages
                SET raw_json = (
                  COALESCE(raw_json, '{}'::jsonb)
                  || jsonb_build_object(
                    'ingestion_route_status', CAST(:status AS text),
                    'ingestion_route_reason', CAST(:reason AS text)
                  )
                )
                WHERE msg_pk = CAST(:msg_pk AS uuid)
                """
            ),
            {
                "msg_pk": msg_pk,
                "status": status,
                "reason": reason,
            },
        )
        db.commit()


def list_unrouted_ingested_messages(*, limit: int = 50) -> list[dict]:
    with SessionLocal() as db:
        rows = db.execute(
            text(
                """
                SELECT
                  tm.msg_pk::text AS msg_pk,
                  tm.chat_id,
                  tm.message_id,
                  tm.text,
                  tm.raw_json,
                  COALESCE(tpc.provider_code, tc.provider_code::text) AS provider_code
                FROM telegram_messages tm
                LEFT JOIN telegram_provider_channels tpc ON tpc.chat_id = tm.chat_id
                LEFT JOIN telegram_chats tc ON tc.chat_id = tm.chat_id
                WHERE tm.raw_json->>'source' = 'telethon_ingestion'
                  AND COALESCE(tm.raw_json->>'ingestion_route_status', '') = ''
                ORDER BY tm.created_at ASC
                LIMIT :limit
                """
            ),
            {"limit": limit},
        ).mappings().all()

    return [dict(r) for r in rows]


def route_ingested_messages_dry_run(*, limit: int = 50) -> IngestionRouteResult:
    """
    Phase 3 dry-run router.

    This only classifies and marks ingested messages. It does not yet call
    the final parser/planner creation service because repos often differ in
    parser entrypoint names. Phase 3b will wire the real parser after we inspect
    the existing parser/planner entrypoints.
    """
    messages = list_unrouted_ingested_messages(limit=limit)

    routed = 0
    ignored = 0
    failed = 0

    for msg in messages:
        try:
            text_value = msg.get("text") or ""
            msg_pk = msg["msg_pk"]

            if not _looks_like_trade_signal(text_value):
                _mark_message_routed(
                    msg_pk=msg_pk,
                    status="ignored",
                    reason="not_trade_signal",
                )
                ignored += 1
                continue

            _mark_message_routed(
                msg_pk=msg_pk,
                status="candidate",
                reason="looks_like_trade_signal",
            )
            routed += 1

        except Exception:
            failed += 1

    return IngestionRouteResult(
        messages_seen=len(messages),
        routed=routed,
        ignored=ignored,
        failed=failed,
    )