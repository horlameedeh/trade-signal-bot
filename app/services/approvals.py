from __future__ import annotations

import hashlib
import json
from datetime import datetime, timezone
from dataclasses import dataclass
from typing import Optional

from sqlalchemy import text

from app.db.session import SessionLocal
from app.decision.models import DecisionResult
from app.parsing.models import ParsedSignal


@dataclass(frozen=True)
class ApprovalCard:
    provider: str
    category: str
    symbol: Optional[str]
    side: Optional[str]
    entry: Optional[str]
    sl: Optional[str]
    tps: list[str]
    risk_tag: str
    reason: str
    message: str
    callback_place: str
    callback_ignore: str
    callback_snooze: str


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


def _approval_category(decision: DecisionResult) -> str:
    if decision.reason == "mubeen_high_risk_requires_approval":
        return "HIGH_RISK"
    if decision.reason == "reenter_requires_approval":
        return "REENTER"
    if decision.reason == "unofficial_or_disclaimer_trade_wait_for_update":
        return "UNOFFICIAL"
    if decision.reason == "ambiguous_or_incomplete_trade_requires_approval":
        return "AMBIGUOUS"
    if decision.reason == "risk_checks_failed":
        return "RISK_CHECK"
    return "GENERAL"


def approval_fingerprint(source_msg_pk: str, decision_reason: str) -> str:
    return hashlib.sha256(f"{source_msg_pk}|{decision_reason}".encode("utf-8")).hexdigest()


def _callback_token(fingerprint: str) -> str:
    return fingerprint[:32]


def build_approval_card(
    *,
    source_msg_pk: str,
    provider_code: str,
    parsed: ParsedSignal,
    decision: DecisionResult,
) -> ApprovalCard:
    symbol = parsed.symbol or (parsed.update.symbol if parsed.update else None)
    side = parsed.side.value if parsed.side else None
    entry = parsed.entry
    sl = parsed.sl
    tps = list(parsed.tps or [])
    risk_tag = _risk_tag_from_flags(parsed.flags)
    category = _approval_category(decision)
    fp = approval_fingerprint(source_msg_pk, decision.reason)
    token = _callback_token(fp)

    callback_place = f"approve:place:{token}"
    callback_ignore = f"approve:ignore:{token}"
    callback_snooze = f"approve:snooze:{token}"

    message = (
        "🟡 Approval Required\n\n"
        f"Provider: {provider_code}\n"
        f"Category: {category}\n"
        f"Symbol: {symbol or '-'}\n"
        f"Side: {side or '-'}\n"
        f"Entry: {entry or '-'}\n"
        f"SL: {sl or '-'}\n"
        f"TPs: {', '.join(tps) if tps else '-'}\n"
        f"Risk: {risk_tag}\n"
        f"Reason: {decision.reason}\n"
        f"Fingerprint: {fp}"
    )

    return ApprovalCard(
        provider=provider_code,
        category=category,
        symbol=symbol,
        side=side,
        entry=entry,
        sl=sl,
        tps=tps,
        risk_tag=risk_tag,
        reason=decision.reason,
        message=message,
        callback_place=callback_place,
        callback_ignore=callback_ignore,
        callback_snooze=callback_snooze,
    )


def _find_plan_id_by_source_msg_pk(db, source_msg_pk: str):
    row = db.execute(
        text(
            """
            SELECT tp.plan_id
            FROM trade_plans tp
            JOIN trade_intents ti ON ti.intent_id = tp.intent_id
            WHERE ti.source_msg_pk = CAST(:pk AS uuid)
            LIMIT 1
            """
        ),
        {"pk": source_msg_pk},
    ).mappings().first()
    return row["plan_id"] if row else None


def _ensure_message_context(db, *, source_msg_pk: str, provider_code: str, raw_text: str) -> tuple[int, int]:
    row = db.execute(
        text(
            """
            SELECT chat_id, message_id
            FROM telegram_messages
            WHERE msg_pk = CAST(:pk AS uuid)
            LIMIT 1
            """
        ),
        {"pk": source_msg_pk},
    ).mappings().first()
    if row:
        return int(row["chat_id"]), int(row["message_id"])

    seed = int(source_msg_pk.replace("-", "")[:15], 16)
    chat_id = 8_000_000_000_000 + (seed % 100_000_000)
    message_id = 1_000_000 + (seed % 1_000_000)

    db.execute(
        text(
            """
            INSERT INTO telegram_chats (chat_id, title, provider_code, channel_kind)
            VALUES (:chat_id, :title, CAST(:provider_code AS provider_code), CAST('mixed' AS channel_kind))
            ON CONFLICT (chat_id) DO NOTHING
            """
        ),
        {
            "chat_id": chat_id,
            "title": f"approval-seed-{provider_code}",
            "provider_code": provider_code,
        },
    )
    db.execute(
        text(
            """
            INSERT INTO telegram_messages (msg_pk, chat_id, message_id, sent_at, text, raw_json)
            VALUES (CAST(:msg_pk AS uuid), :chat_id, :message_id, :sent_at, :text, CAST(:raw_json AS jsonb))
            ON CONFLICT (msg_pk) DO NOTHING
            """
        ),
        {
            "msg_pk": source_msg_pk,
            "chat_id": chat_id,
            "message_id": message_id,
            "sent_at": datetime.now(timezone.utc),
            "text": raw_text,
            "raw_json": "{}",
        },
    )
    return chat_id, message_id


def _ensure_account_id(db, provider_code: str) -> str:
    row = db.execute(
        text(
            """
            SELECT broker_account_id AS account_id
            FROM provider_account_routes
            WHERE provider_code = :provider_code
              AND is_active = true
            ORDER BY updated_at DESC NULLS LAST, created_at DESC
            LIMIT 1
            """
        ),
        {"provider_code": provider_code},
    ).mappings().first()
    if row:
        return str(row["account_id"])

    row = db.execute(
        text(
            """
            SELECT account_id
            FROM broker_accounts
            WHERE is_active = true
            ORDER BY created_at ASC
            LIMIT 1
            """
        )
    ).mappings().first()
    if row:
        return str(row["account_id"])

    row = db.execute(
        text(
            """
            INSERT INTO broker_accounts (broker, platform, kind, label, allowed_providers)
            VALUES (
              CAST('vantage' AS broker_code),
              CAST('mt5' AS platform_code),
              CAST('demo' AS account_kind),
              :label,
              ARRAY[CAST(:provider_code AS provider_code)]
            )
            RETURNING account_id
            """
        ),
        {
            "label": f"approval-seed-{provider_code}",
            "provider_code": provider_code,
        },
    ).mappings().first()
    return str(row["account_id"])


def _ensure_intent_id(
    db,
    *,
    source_msg_pk: str,
    provider_code: str,
    parsed: ParsedSignal,
    decision: DecisionResult,
):
    row = db.execute(
        text(
            """
            SELECT intent_id
            FROM trade_intents
            WHERE source_msg_pk = CAST(:pk AS uuid)
            LIMIT 1
            """
        ),
        {"pk": source_msg_pk},
    ).mappings().first()
    if row:
        return row["intent_id"]

    chat_id, source_message_id = _ensure_message_context(
        db,
        source_msg_pk=source_msg_pk,
        provider_code=provider_code,
        raw_text=parsed.raw_text,
    )

    side = parsed.side.value.lower() if parsed.side else None
    order_type = parsed.order_type.value if parsed.order_type else None
    tp_prices = [float(tp) for tp in (parsed.tps or [])]
    tp_prices_value = "{" + ",".join(str(tp) for tp in tp_prices) + "}" if tp_prices else None

    row = db.execute(
        text(
            """
            INSERT INTO trade_intents (
              provider,
              chat_id,
              source_msg_pk,
              source_message_id,
              dedupe_hash,
              parse_confidence,
              status,
              symbol_raw,
              side,
              order_type,
              entry_price,
              sl_price,
              tp_prices,
              risk_tag,
              is_unofficial,
              instructions,
              meta
            )
            VALUES (
              CAST(:provider AS provider_code),
              :chat_id,
              CAST(:source_msg_pk AS uuid),
              :source_message_id,
              :dedupe_hash,
              :parse_confidence,
              CAST('candidate_pending' AS intent_status),
              :symbol_raw,
              CAST(:side AS trade_side),
              CAST(:order_type AS order_type),
              :entry_price,
              :sl_price,
              CAST(:tp_prices AS numeric[]),
              CAST(:risk_tag AS risk_tag),
              :is_unofficial,
              :instructions,
              CAST(:meta AS jsonb)
            )
            ON CONFLICT (source_msg_pk) DO UPDATE
              SET updated_at = now()
            RETURNING intent_id
            """
        ),
        {
            "provider": provider_code,
            "chat_id": chat_id,
            "source_msg_pk": source_msg_pk,
            "source_message_id": source_message_id,
            "dedupe_hash": approval_fingerprint(source_msg_pk, decision.reason),
            "parse_confidence": float(parsed.confidence) / 100.0,
            "symbol_raw": parsed.raw_symbol,
            "side": side,
            "order_type": order_type,
            "entry_price": float(parsed.entry) if parsed.entry else None,
            "sl_price": float(parsed.sl) if parsed.sl else None,
            "tp_prices": tp_prices_value,
            "risk_tag": _risk_tag_from_flags(parsed.flags),
            "is_unofficial": parsed.unofficial,
            "instructions": parsed.clean_text,
            "meta": json.dumps({"source": "approvals_service", "decision_reason": decision.reason}),
        },
    ).mappings().first()
    return row["intent_id"]


def _ensure_candidate_plan_for_intent(
    db,
    *,
    source_msg_pk: str,
    provider_code: str,
    parsed: ParsedSignal,
    decision: DecisionResult,
):
    intent_id = _ensure_intent_id(
        db,
        source_msg_pk=source_msg_pk,
        provider_code=provider_code,
        parsed=parsed,
        decision=decision,
    )

    row = db.execute(
        text(
            """
            SELECT plan_id
            FROM trade_plans
            WHERE intent_id = CAST(:intent_id AS uuid)
            LIMIT 1
            """
        ),
        {"intent_id": str(intent_id)},
    ).mappings().first()
    if row:
        return row["plan_id"]

    account_id = _ensure_account_id(db, provider_code)

    plan_row = db.execute(
        text(
            """
            INSERT INTO trade_plans (
              intent_id,
              account_id,
              policy_outcome,
              requires_approval,
              policy_reasons,
              meta
            )
            VALUES (
              CAST(:intent_id AS uuid),
              CAST(:account_id AS uuid),
              CAST('require_approval' AS policy_outcome),
              TRUE,
              ARRAY[:reason]::text[],
              CAST(:meta AS jsonb)
            )
            RETURNING plan_id
            """
        ),
        {
            "intent_id": str(intent_id),
            "account_id": account_id,
            "reason": decision.reason,
            "meta": json.dumps({"source": "approvals_service"}),
        },
    ).mappings().first()

    if not plan_row:
        raise RuntimeError("Failed to create trade_plan for approval flow")

    return plan_row["plan_id"]


def create_approval_if_missing(
    *,
    source_msg_pk: str,
    provider_code: str,
    parsed: ParsedSignal,
    decision: DecisionResult,
    control_chat_id: int | None = None,
    control_message_id: int | None = None,
) -> ApprovalCard:
    card = build_approval_card(
        source_msg_pk=source_msg_pk,
        provider_code=provider_code,
        parsed=parsed,
        decision=decision,
    )
    fp = approval_fingerprint(source_msg_pk, decision.reason)

    with SessionLocal() as db:
        existing = db.execute(
            text(
                """
                SELECT a.approval_id
                FROM approvals a
                JOIN trade_plans tp ON tp.plan_id = a.plan_id
                JOIN trade_intents ti ON ti.intent_id = tp.intent_id
                                WHERE ti.source_msg_pk = CAST(:pk AS uuid)
                  AND a.notes LIKE :fp_like
                LIMIT 1
                """
            ),
            {"pk": source_msg_pk, "fp_like": f"%Fingerprint: {fp}%"},
        ).scalar()

        if existing:
            db.commit()
            return card

        plan_id = _find_plan_id_by_source_msg_pk(db, source_msg_pk)
        if not plan_id:
            plan_id = _ensure_candidate_plan_for_intent(
                db,
                source_msg_pk=source_msg_pk,
                provider_code=provider_code,
                parsed=parsed,
                decision=decision,
            )

        db.execute(
            text(
                """
                INSERT INTO approvals (
                  plan_id,
                  control_chat_id,
                  control_message_id,
                  notes
                )
                VALUES (
                                    CAST(:plan_id AS uuid),
                  :control_chat_id,
                  :control_message_id,
                  :notes
                )
                """
            ),
            {
                "plan_id": plan_id,
                "control_chat_id": control_chat_id,
                "control_message_id": control_message_id,
                "notes": card.message,
            },
        )
        db.commit()

    return card
