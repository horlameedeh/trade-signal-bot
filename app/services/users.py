from __future__ import annotations

from dataclasses import dataclass

from sqlalchemy import text

from app.db.session import SessionLocal


@dataclass(frozen=True)
class TradeBotUser:
    user_id: str
    telegram_user_id: int
    display_name: str | None
    role: str
    is_active: bool


def get_or_create_user(
    *,
    telegram_user_id: int,
    display_name: str | None = None,
    role: str = "user",
) -> TradeBotUser:
    with SessionLocal() as db:
        db.execute(
            text(
                """
                INSERT INTO users (telegram_user_id, display_name, role)
                VALUES (:telegram_user_id, :display_name, :role)
                ON CONFLICT (telegram_user_id)
                DO UPDATE SET
                  display_name = COALESCE(EXCLUDED.display_name, users.display_name),
                  updated_at = now()
                """
            ),
            {
                "telegram_user_id": telegram_user_id,
                "display_name": display_name,
                "role": role,
            },
        )
        db.commit()

        row = db.execute(
            text(
                """
                SELECT user_id::text, telegram_user_id, display_name, role, is_active
                FROM users
                WHERE telegram_user_id = :telegram_user_id
                LIMIT 1
                """
            ),
            {"telegram_user_id": telegram_user_id},
        ).mappings().first()

    if not row:
        raise RuntimeError("failed to create or load user")

    return TradeBotUser(
        user_id=row["user_id"],
        telegram_user_id=row["telegram_user_id"],
        display_name=row["display_name"],
        role=row["role"],
        is_active=row["is_active"],
    )


def get_user_by_telegram_id(*, telegram_user_id: int) -> TradeBotUser | None:
    with SessionLocal() as db:
        row = db.execute(
            text(
                """
                SELECT user_id::text, telegram_user_id, display_name, role, is_active
                FROM users
                WHERE telegram_user_id = :telegram_user_id
                LIMIT 1
                """
            ),
            {"telegram_user_id": telegram_user_id},
        ).mappings().first()

    if not row:
        return None

    return TradeBotUser(
        user_id=row["user_id"],
        telegram_user_id=row["telegram_user_id"],
        display_name=row["display_name"],
        role=row["role"],
        is_active=row["is_active"],
    )


def link_control_chat(*, user_id: str, telegram_chat_id: int, label: str | None = None) -> None:
    with SessionLocal() as db:
        db.execute(
            text(
                """
                INSERT INTO user_control_chats (user_id, telegram_chat_id, label)
                VALUES (CAST(:user_id AS uuid), :telegram_chat_id, :label)
                ON CONFLICT (telegram_chat_id)
                DO UPDATE SET
                  user_id = EXCLUDED.user_id,
                  label = COALESCE(EXCLUDED.label, user_control_chats.label),
                  is_active = true
                """
            ),
            {
                "user_id": user_id,
                "telegram_chat_id": telegram_chat_id,
                "label": label,
            },
        )
        db.commit()


def resolve_user_from_control_chat(*, telegram_chat_id: int) -> TradeBotUser | None:
    with SessionLocal() as db:
        row = db.execute(
            text(
                """
                SELECT u.user_id::text, u.telegram_user_id, u.display_name, u.role, u.is_active
                FROM user_control_chats c
                JOIN users u ON u.user_id = c.user_id
                WHERE c.telegram_chat_id = :telegram_chat_id
                  AND c.is_active = true
                  AND u.is_active = true
                LIMIT 1
                """
            ),
            {"telegram_chat_id": telegram_chat_id},
        ).mappings().first()

    if not row:
        return None

    return TradeBotUser(
        user_id=row["user_id"],
        telegram_user_id=row["telegram_user_id"],
        display_name=row["display_name"],
        role=row["role"],
        is_active=row["is_active"],
    )
