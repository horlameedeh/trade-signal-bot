from __future__ import annotations

from dataclasses import dataclass

from sqlalchemy import text

from app.db.session import SessionLocal


@dataclass(frozen=True)
class TenantAccount:
    account_id: str
    user_id: str | None
    broker: str
    platform: str
    label: str | None
    is_active: bool


def assign_account_to_user(*, account_id: str, user_id: str) -> None:
    with SessionLocal() as db:
        db.execute(
            text(
                """
                UPDATE broker_accounts
                SET user_id = CAST(:user_id AS uuid)
                WHERE account_id = CAST(:account_id AS uuid)
                """
            ),
            {"account_id": account_id, "user_id": user_id},
        )
        db.commit()


def get_user_accounts(*, user_id: str) -> list[TenantAccount]:
    with SessionLocal() as db:
        rows = db.execute(
            text(
                """
                SELECT
                  account_id::text AS account_id,
                  user_id::text AS user_id,
                  broker,
                  platform,
                  label,
                  is_active
                FROM broker_accounts
                WHERE user_id = CAST(:user_id AS uuid)
                ORDER BY created_at ASC
                """
            ),
            {"user_id": user_id},
        ).mappings().all()

    return [
        TenantAccount(
            account_id=r["account_id"],
            user_id=r["user_id"],
            broker=r["broker"],
            platform=r["platform"],
            label=r["label"],
            is_active=r["is_active"],
        )
        for r in rows
    ]


def get_user_account_by_label(*, user_id: str, label: str) -> TenantAccount | None:
    with SessionLocal() as db:
        row = db.execute(
            text(
                """
                SELECT
                  account_id::text AS account_id,
                  user_id::text AS user_id,
                  broker,
                  platform,
                  label,
                  is_active
                FROM broker_accounts
                WHERE user_id = CAST(:user_id AS uuid)
                  AND label = :label
                LIMIT 1
                """
            ),
            {"user_id": user_id, "label": label},
        ).mappings().first()

    if not row:
        return None

    return TenantAccount(
        account_id=row["account_id"],
        user_id=row["user_id"],
        broker=row["broker"],
        platform=row["platform"],
        label=row["label"],
        is_active=row["is_active"],
    )


def resolve_active_user_account(
    *,
    user_id: str,
    broker: str,
    platform: str,
    provider: str | None = None,
) -> TenantAccount | None:
    provider_filter = ""
    params = {
        "user_id": user_id,
        "broker": broker,
        "platform": platform,
    }

    if provider:
        provider_filter = """
          AND (
            allowed_providers IS NULL
            OR cardinality(allowed_providers) = 0
            OR CAST(:provider AS provider_code) = ANY(allowed_providers)
          )
        """
        params["provider"] = provider

    with SessionLocal() as db:
        row = db.execute(
            text(
                f"""
                SELECT
                  account_id::text AS account_id,
                  user_id::text AS user_id,
                  broker,
                  platform,
                  label,
                  is_active
                FROM broker_accounts
                WHERE user_id = CAST(:user_id AS uuid)
                  AND broker = :broker
                  AND platform = :platform
                  AND is_active = true
                  {provider_filter}
                ORDER BY created_at ASC
                LIMIT 1
                """
            ),
            params,
        ).mappings().first()

    if not row:
        return None

    return TenantAccount(
        account_id=row["account_id"],
        user_id=row["user_id"],
        broker=row["broker"],
        platform=row["platform"],
        label=row["label"],
        is_active=row["is_active"],
    )


def assert_account_belongs_to_user(*, account_id: str, user_id: str) -> None:
    with SessionLocal() as db:
        found = db.execute(
            text(
                """
                SELECT 1
                FROM broker_accounts
                WHERE account_id = CAST(:account_id AS uuid)
                  AND user_id = CAST(:user_id AS uuid)
                LIMIT 1
                """
            ),
            {"account_id": account_id, "user_id": user_id},
        ).scalar()

    if not found:
        raise PermissionError("broker account does not belong to user")
