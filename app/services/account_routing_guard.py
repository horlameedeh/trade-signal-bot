from __future__ import annotations

from dataclasses import dataclass

from sqlalchemy import text

from app.db.session import SessionLocal


class AccountRoutingError(RuntimeError):
    pass


@dataclass(frozen=True)
class ActiveAccountRoute:
    account_id: str
    broker: str
    platform: str
    label: str


def get_unique_active_account(*, broker: str, platform: str) -> ActiveAccountRoute:
    with SessionLocal() as db:
        rows = db.execute(
            text(
                """
                SELECT account_id::text AS account_id,
                       broker::text AS broker,
                       platform::text AS platform,
                       label
                FROM broker_accounts
                WHERE broker::text = :broker
                  AND platform::text = :platform
                  AND is_active = true
                ORDER BY updated_at DESC, created_at DESC
                """
            ),
            {"broker": broker, "platform": platform},
        ).mappings().all()

    if not rows:
        raise AccountRoutingError(f"No active broker account found for {broker}/{platform}")

    if len(rows) > 1:
        labels = ", ".join(r["label"] for r in rows)
        raise AccountRoutingError(
            f"Ambiguous active broker accounts for {broker}/{platform}: {labels}"
        )

    r = rows[0]
    return ActiveAccountRoute(
        account_id=r["account_id"],
        broker=r["broker"],
        platform=r["platform"],
        label=r["label"],
    )
