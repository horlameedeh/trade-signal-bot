from __future__ import annotations

import json
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from enum import Enum
from typing import Optional

from sqlalchemy import text

from app.db.session import SessionLocal


class CallbackAction(str, Enum):
    PLACE = "place"
    IGNORE = "ignore"
    SNOOZE = "snooze"


@dataclass(frozen=True)
class ApprovalCallbackResult:
    ok: bool
    action: CallbackAction
    fingerprint: str
    approval_found: bool
    control_action_created: bool
    reason: str


def parse_callback_data(data: str) -> tuple[CallbackAction, str]:
    parts = (data or "").split(":")
    if len(parts) != 3 or parts[0] != "approve":
        raise ValueError(f"Invalid callback data: {data!r}")
    action_raw = parts[1].strip().lower()
    fp = parts[2].strip()
    if action_raw not in {"place", "ignore", "snooze"}:
        raise ValueError(f"Unknown callback action: {action_raw!r}")
    return CallbackAction(action_raw), fp


def _ensure_control_actions_table(db) -> None:
    db.execute(
        text(
            """
            CREATE TABLE IF NOT EXISTS control_actions (
              id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
              created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
              telegram_user_id BIGINT,
              control_chat_id BIGINT,
              control_message_id BIGINT,
              action TEXT NOT NULL,
              payload JSONB NOT NULL DEFAULT '{}'::jsonb,
              status TEXT NOT NULL DEFAULT 'queued'
            );
            """
        )
    )
    db.execute(
        text(
            """
            CREATE INDEX IF NOT EXISTS idx_control_actions_status_time
            ON control_actions(status, created_at DESC);
            """
        )
    )


def _ensure_control_chat(db, control_chat_id: Optional[int]) -> None:
    if control_chat_id is None:
        return
    db.execute(
        text(
            """
            INSERT INTO telegram_chats (chat_id, title, channel_kind, is_control_chat)
            VALUES (:chat_id, :title, CAST('mixed' AS channel_kind), TRUE)
            ON CONFLICT (chat_id) DO NOTHING
            """
        ),
        {
            "chat_id": control_chat_id,
            "title": "Control Chat",
        },
    )


def _find_approval_by_fingerprint(db, fingerprint: str):
    row = db.execute(
        text(
            """
            SELECT a.*
            FROM approvals a
            WHERE a.notes LIKE :fp_like
            ORDER BY a.created_at DESC
            LIMIT 1
            """
        ),
        {"fp_like": f"%Fingerprint: {fingerprint}%"},
    ).mappings().first()
    return row


def _decision_enum_value(action: CallbackAction) -> str:
    return {
        CallbackAction.PLACE: "approve",
        CallbackAction.IGNORE: "reject",
        CallbackAction.SNOOZE: "snooze",
    }[action]


def _create_control_action_if_missing(
    db,
    *,
    fingerprint: str,
    callback_action: CallbackAction,
    telegram_user_id: Optional[int],
    control_chat_id: Optional[int],
    control_message_id: Optional[int],
    approval_id: str,
) -> bool:
    payload = {
        "fingerprint": fingerprint,
        "callback_action": callback_action.value,
        "approval_id": approval_id,
        "source": "approval_callback",
    }

    existing = db.execute(
        text(
            """
            SELECT 1
            FROM control_actions
            WHERE (payload->>'fingerprint') = :fp
              AND (payload->>'callback_action') = :act
            LIMIT 1
            """
        ),
        {"fp": fingerprint, "act": callback_action.value},
    ).scalar()

    if existing:
        return False

    action_name = {
        CallbackAction.PLACE: "approval_place",
        CallbackAction.IGNORE: "approval_ignore",
        CallbackAction.SNOOZE: "approval_snooze",
    }[callback_action]

    db.execute(
        text(
            """
            INSERT INTO control_actions (
              telegram_user_id,
              control_chat_id,
              control_message_id,
              action,
              payload,
              status
            )
            VALUES (
              :uid,
              :chat_id,
              :message_id,
              :action,
              CAST(:payload AS jsonb),
              'queued'
            )
            """
        ),
        {
            "uid": telegram_user_id,
            "chat_id": control_chat_id,
            "message_id": control_message_id,
            "action": action_name,
            "payload": json.dumps(payload, default=str),
        },
    )
    return True


def handle_approval_callback(
    *,
    callback_data: str,
    telegram_user_id: Optional[int],
    control_chat_id: Optional[int],
    control_message_id: Optional[int],
) -> ApprovalCallbackResult:
    action, fingerprint = parse_callback_data(callback_data)

    with SessionLocal() as db:
        _ensure_control_actions_table(db)
        _ensure_control_chat(db, control_chat_id)

        approval = _find_approval_by_fingerprint(db, fingerprint)
        if not approval:
            db.commit()
            return ApprovalCallbackResult(
                ok=False,
                action=action,
                fingerprint=fingerprint,
                approval_found=False,
                control_action_created=False,
                reason="approval_not_found",
            )

        snooze_until = None
        if action == CallbackAction.SNOOZE:
            snooze_until = datetime.now(timezone.utc) + timedelta(minutes=10)

        db.execute(
            text(
                """
                UPDATE approvals
                SET decision = :decision,
                    decision_by_telegram_user_id = :uid,
                    decided_at = now(),
                    snooze_until = :snooze_until,
                    control_chat_id = COALESCE(:control_chat_id, control_chat_id),
                    control_message_id = COALESCE(:control_message_id, control_message_id)
                WHERE approval_id = CAST(:approval_id AS uuid)
                """
            ),
            {
                "decision": _decision_enum_value(action),
                "uid": telegram_user_id,
                "snooze_until": snooze_until,
                "control_chat_id": control_chat_id,
                "control_message_id": control_message_id,
                "approval_id": str(approval["approval_id"]),
            },
        )

        created = _create_control_action_if_missing(
            db,
            fingerprint=fingerprint,
            callback_action=action,
            telegram_user_id=telegram_user_id,
            control_chat_id=control_chat_id,
            control_message_id=control_message_id,
            approval_id=str(approval["approval_id"]),
        )

        db.commit()

    return ApprovalCallbackResult(
        ok=True,
        action=action,
        fingerprint=fingerprint,
        approval_found=True,
        control_action_created=created,
        reason="ok",
    )
