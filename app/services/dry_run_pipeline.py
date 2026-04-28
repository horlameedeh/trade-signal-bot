from __future__ import annotations

import hashlib
import json
from dataclasses import dataclass
from decimal import Decimal, InvalidOperation
from typing import Any

from sqlalchemy import text

from app.db.session import SessionLocal
from app.decision.engine import decide_signal
from app.decision.models import DecisionContext
from app.execution.mock_executor import plan_family_execution
from app.parsing.parser import parse_message
from app.services.trade_writer import create_trade_family_and_legs


@dataclass(frozen=True)
class DryRunResult:
    chat_id: int
    message_id: int
    provider: str | None
    parsed_type: str
    decision_action: str | None
    intent_created: bool
    family_created: bool
    mock_executions_created: int
    reason: str


def _dedupe_hash(*, provider: str, chat_id: int, message_id: int, text_value: str) -> str:
    payload = f"{provider}|{chat_id}|{message_id}|{text_value}"
    return hashlib.sha256(payload.encode("utf-8")).hexdigest()


def _to_decimal_or_none(value: str | None) -> str | None:
    if value is None:
        return None
    try:
        return str(Decimal(str(value).replace(",", "")))
    except (InvalidOperation, ValueError):
        return None


def _to_decimal_array(values: list[str]) -> list[str]:
    out: list[str] = []
    for value in values:
        decimal_value = _to_decimal_or_none(value)
        if decimal_value is not None:
            out.append(decimal_value)
    return out


def _risk_tag_from_flags(flags: list[str]) -> str:
    flags_set = set(flags or [])
    if "HALF_OF_HALF" in flags_set:
        return "half"
    if "HALF_RISK" in flags_set or "HALF_SIZE" in flags_set:
        return "half"
    if "HIGH_RISK" in flags_set:
        return "high"
    if "TINY_RISK" in flags_set:
        return "tiny"
    if "NORMAL_RISK" in flags_set:
        return "normal"
    return "unknown"


def _get_message(chat_id: int, message_id: int) -> dict[str, Any] | None:
    with SessionLocal() as db:
        row = db.execute(
            text(
                """
                SELECT
                  tm.msg_pk::text AS msg_pk,
                  tm.chat_id,
                  tm.message_id,
                  tm.text,
                  tm.sent_at,
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

    return dict(row) if row else None


def _persist_new_trade_intent_if_missing(*, row: dict[str, Any], parsed) -> bool:
    provider = row["provider_code"]
    chat_id = row["chat_id"]
    message_id = row["message_id"]
    msg_pk = row["msg_pk"]
    text_value = row["text"] or ""

    dedupe = _dedupe_hash(
        provider=provider,
        chat_id=chat_id,
        message_id=message_id,
        text_value=text_value,
    )

    with SessionLocal() as db:
        existing = db.execute(
            text(
                """
                SELECT intent_id
                FROM trade_intents
                WHERE source_msg_pk = CAST(:msg_pk AS uuid)
                LIMIT 1
                """
            ),
            {"msg_pk": msg_pk},
        ).scalar()

        if existing:
            return False

        tp_array = _to_decimal_array(parsed.tps or [])
        flags_set = set(parsed.flags or [])
        meta = {
            "dry_run": True,
            "flags": parsed.flags,
            "message_type": parsed.message_type.value,
            "confidence": parsed.confidence,
        }

        db.execute(
            text(
                """
                INSERT INTO trade_intents (
                  provider,
                  chat_id,
                  source_msg_pk,
                  source_message_id,
                  dedupe_hash,
                  parse_confidence,
                  symbol_canonical,
                  symbol_raw,
                  side,
                  order_type,
                  entry_price,
                  sl_price,
                  tp_prices,
                  has_runner,
                  risk_tag,
                  is_scalp,
                  is_swing,
                  is_unofficial,
                  reenter_tag,
                  instructions,
                  meta
                )
                VALUES (
                  :provider,
                  :chat_id,
                  CAST(:source_msg_pk AS uuid),
                  :source_message_id,
                  :dedupe_hash,
                  :parse_confidence,
                  :symbol_canonical,
                  :symbol_raw,
                  :side,
                  :order_type,
                  :entry_price,
                  :sl_price,
                  CAST(:tp_prices AS numeric(18,10)[]),
                  :has_runner,
                  :risk_tag,
                  :is_scalp,
                  :is_swing,
                  :is_unofficial,
                  :reenter_tag,
                  :instructions,
                  CAST(:meta AS jsonb)
                )
                """
            ),
            {
                "provider": provider,
                "chat_id": chat_id,
                "source_msg_pk": msg_pk,
                "source_message_id": message_id,
                "dedupe_hash": dedupe,
                "parse_confidence": str(parsed.confidence / 100),
                "symbol_canonical": parsed.symbol,
                "symbol_raw": parsed.raw_symbol,
                "side": parsed.side.value.lower() if parsed.side else None,
                "order_type": parsed.order_type.value if parsed.order_type else None,
                "entry_price": parsed.entry,
                "sl_price": parsed.sl,
                "tp_prices": "{" + ",".join(tp_array) + "}" if tp_array else "{}",
                "has_runner": any("runner" in value.lower() for value in (parsed.tps or [])),
                "risk_tag": _risk_tag_from_flags(parsed.flags or []),
                "is_scalp": "SCALP" in flags_set,
                "is_swing": "SWING" in flags_set,
                "is_unofficial": bool(parsed.unofficial),
                "reenter_tag": "REENTER" in flags_set,
                "instructions": text_value,
                "meta": json.dumps(meta, default=str),
            },
        )
        db.commit()

    return True


def _ensure_plan_for_intent(*, source_msg_pk: str) -> None:
    with SessionLocal() as db:
        db.execute(
            text(
                """
                INSERT INTO trade_plans (
                  intent_id,
                  account_id,
                  policy_outcome,
                  requires_approval,
                  policy_reasons
                )
                SELECT
                  ti.intent_id,
                  par.broker_account_id,
                  'allow'::policy_outcome,
                  false,
                  ARRAY['dry_run_auto']::text[]
                FROM trade_intents ti
                JOIN provider_account_routes par
                                    ON par.provider_code = CAST(ti.provider AS text)
                 AND par.is_active = true
                WHERE ti.source_msg_pk = CAST(:source_msg_pk AS uuid)
                  AND NOT EXISTS (
                    SELECT 1
                    FROM trade_plans tp
                    WHERE tp.intent_id = ti.intent_id
                  )
                LIMIT 1
                """
            ),
            {"source_msg_pk": source_msg_pk},
        )
        db.commit()


def process_message_dry_run(*, chat_id: int, message_id: int) -> DryRunResult:
    row = _get_message(chat_id, message_id)
    if not row:
        return DryRunResult(
            chat_id=chat_id,
            message_id=message_id,
            provider=None,
            parsed_type="UNKNOWN",
            decision_action=None,
            intent_created=False,
            family_created=False,
            mock_executions_created=0,
            reason="message_not_found",
        )

    provider = row["provider_code"]
    if not provider:
        return DryRunResult(
            chat_id=chat_id,
            message_id=message_id,
            provider=None,
            parsed_type="UNKNOWN",
            decision_action=None,
            intent_created=False,
            family_created=False,
            mock_executions_created=0,
            reason="missing_provider",
        )

    parsed = parse_message(provider, row["text"] or "")
    parsed_type = parsed.message_type.value

    if parsed_type != "NEW_TRADE":
        return DryRunResult(
            chat_id=chat_id,
            message_id=message_id,
            provider=provider,
            parsed_type=parsed_type,
            decision_action=None,
            intent_created=False,
            family_created=False,
            mock_executions_created=0,
            reason="not_new_trade",
        )

    decision = decide_signal(
        DecisionContext(
            provider_code=provider,
            parsed=parsed,
            duplicate=False,
            risk_checks_pass=True,
        )
    )

    if decision.action.value not in {"AUTO_PLACE", "PENDING_UPDATE"}:
        return DryRunResult(
            chat_id=chat_id,
            message_id=message_id,
            provider=provider,
            parsed_type=parsed_type,
            decision_action=decision.action.value,
            intent_created=False,
            family_created=False,
            mock_executions_created=0,
            reason="not_auto_placeable",
        )

    intent_created = _persist_new_trade_intent_if_missing(row=row, parsed=parsed)
    _ensure_plan_for_intent(source_msg_pk=row["msg_pk"])

    before_family = None
    with SessionLocal() as db:
        before_family = db.execute(
            text(
                """
                SELECT family_id::text
                FROM trade_families
                WHERE source_msg_pk = CAST(:source_msg_pk AS uuid)
                LIMIT 1
                """
            ),
            {"source_msg_pk": row["msg_pk"]},
        ).scalar()

    family_result = create_trade_family_and_legs(source_msg_pk=row["msg_pk"])

    family_created = before_family is None
    mock = plan_family_execution(family_id=family_result.family_id)

    return DryRunResult(
        chat_id=chat_id,
        message_id=message_id,
        provider=provider,
        parsed_type=parsed_type,
        decision_action=decision.action.value,
        intent_created=intent_created,
        family_created=family_created,
        mock_executions_created=mock.legs_planned,
        reason="ok",
    )
