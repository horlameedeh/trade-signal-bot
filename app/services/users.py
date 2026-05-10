from __future__ import annotations

from dataclasses import dataclass

from sqlalchemy import text

from app.db.session import SessionLocal


@dataclass(frozen=True)
class TradeBotUser:
    user_id: str
    telegram_user_id: int | None
    display_name: str | None
    role: str
    is_active: bool
    identity_slot: str | None = None


IDENTITY_SLOT_SPECS: tuple[tuple[str, str], ...] = (
    ("user001", "TradeSignal User 001"),
    ("user002", "TradeSignal User 002"),
    ("user003", "TradeSignal User 003"),
    ("user004", "TradeSignal User 004"),
    ("user005", "TradeSignal User 005"),
)


def _row_to_user(row: dict) -> TradeBotUser:
    return TradeBotUser(
        user_id=row["user_id"],
        telegram_user_id=row["telegram_user_id"],
        display_name=row["display_name"],
        role=row["role"],
        is_active=row["is_active"],
        identity_slot=row.get("identity_slot"),
    )


def _load_user_by_telegram_id(*, db, telegram_user_id: int):
    return db.execute(
        text(
            """
            SELECT user_id::text, telegram_user_id, display_name, role, is_active, identity_slot
            FROM users
            WHERE telegram_user_id = :telegram_user_id
            LIMIT 1
            """
        ),
        {"telegram_user_id": telegram_user_id},
    ).mappings().first()


def _slot_order_case_sql() -> str:
    return "\n".join(
        f"WHEN '{identity_slot}' THEN {index}"
        for index, (identity_slot, _) in enumerate(IDENTITY_SLOT_SPECS, start=1)
    )


def _refresh_existing_user(*, db, telegram_user_id: int, display_name: str | None):
    if display_name:
        db.execute(
            text(
                """
                UPDATE users
                SET
                  display_name = CASE
                    WHEN identity_slot IS NULL THEN :display_name
                    ELSE display_name
                  END,
                  updated_at = now()
                WHERE telegram_user_id = :telegram_user_id
                """
            ),
            {
                "telegram_user_id": telegram_user_id,
                "display_name": display_name,
            },
        )

    row = _load_user_by_telegram_id(db=db, telegram_user_id=telegram_user_id)
    if not row:
        raise RuntimeError("failed to load existing user")
    return row


def _claim_next_identity_slot(*, db, telegram_user_id: int):
    row = db.execute(
        text(
            f"""
            SELECT user_id::text, identity_slot
            FROM users
            WHERE telegram_user_id IS NULL
              AND identity_slot IS NOT NULL
              AND is_active = true
            ORDER BY CASE identity_slot
              {_slot_order_case_sql()}
              ELSE 999
            END,
            created_at,
            user_id
            LIMIT 1
            FOR UPDATE SKIP LOCKED
            """
        )
    ).mappings().first()

    if not row:
        return None

    db.execute(
        text(
            """
            UPDATE users
            SET telegram_user_id = :telegram_user_id,
                updated_at = now()
            WHERE user_id = CAST(:user_id AS uuid)
              AND telegram_user_id IS NULL
            """
        ),
        {
            "telegram_user_id": telegram_user_id,
            "user_id": row["user_id"],
        },
    )
    return _load_user_by_telegram_id(db=db, telegram_user_id=telegram_user_id)


def get_or_create_user(
    *,
    telegram_user_id: int,
    display_name: str | None = None,
    role: str = "user",
) -> TradeBotUser:
    with SessionLocal() as db:
        existing = _load_user_by_telegram_id(db=db, telegram_user_id=telegram_user_id)
        if existing:
            row = _refresh_existing_user(
                db=db,
                telegram_user_id=telegram_user_id,
                display_name=display_name,
            )
            db.commit()
            return _row_to_user(row)

        claimed = None
        if role == "user":
            claimed = _claim_next_identity_slot(db=db, telegram_user_id=telegram_user_id)

        if claimed:
            db.commit()
            return _row_to_user(claimed)

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
        row = _load_user_by_telegram_id(db=db, telegram_user_id=telegram_user_id)
        db.commit()

    if not row:
        raise RuntimeError("failed to create or load user")

    return _row_to_user(row)


def upsert_identity_slot_user(
    *,
    identity_slot: str,
    display_name: str,
    role: str = "user",
    telegram_user_id: int | None = None,
) -> TradeBotUser:
    with SessionLocal() as db:
        db.execute(
            text(
                """
                INSERT INTO users (identity_slot, telegram_user_id, display_name, role)
                VALUES (:identity_slot, :telegram_user_id, :display_name, :role)
                ON CONFLICT (identity_slot)
                DO UPDATE SET
                  display_name = EXCLUDED.display_name,
                  role = EXCLUDED.role,
                  telegram_user_id = CASE
                    WHEN users.telegram_user_id IS NULL THEN EXCLUDED.telegram_user_id
                    ELSE users.telegram_user_id
                  END,
                  updated_at = now()
                """
            ),
            {
                "identity_slot": identity_slot,
                "telegram_user_id": telegram_user_id,
                "display_name": display_name,
                "role": role,
            },
        )
        db.commit()

        row = db.execute(
            text(
                """
                SELECT user_id::text, telegram_user_id, display_name, role, is_active, identity_slot
                FROM users
                WHERE identity_slot = :identity_slot
                LIMIT 1
                """
            ),
            {"identity_slot": identity_slot},
        ).mappings().first()

    if not row:
        raise RuntimeError("failed to create or load identity slot user")

    return _row_to_user(row)


def get_user_by_telegram_id(*, telegram_user_id: int) -> TradeBotUser | None:
    with SessionLocal() as db:
        row = _load_user_by_telegram_id(db=db, telegram_user_id=telegram_user_id)

    if not row:
        return None

    return _row_to_user(row)


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
                SELECT u.user_id::text, u.telegram_user_id, u.display_name, u.role, u.is_active, u.identity_slot
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

    return _row_to_user(row)
