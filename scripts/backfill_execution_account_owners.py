from __future__ import annotations

import argparse
import sys
from pathlib import Path

from sqlalchemy import text

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from app.db.session import SessionLocal
from app.services.users import get_or_create_user


DEFAULT_BROKERS = [
    "vantage",
    "startrader",
    "bullwaves",
    "ftmo",
    "traderscale",
    "fundednext",
]


def _csv(value: str | None) -> list[str]:
    if not value:
        return []
    return [part.strip().lower() for part in value.split(",") if part.strip()]


def _pick_identity(
    *,
    broker: str,
    explicit_telegram_user_id: int | None,
    explicit_display_name: str | None,
    default_telegram_user_id: int | None,
    default_display_name: str | None,
) -> tuple[int, str]:
    if explicit_telegram_user_id is not None:
        return explicit_telegram_user_id, explicit_display_name or broker.title()

    if default_telegram_user_id is not None:
        return default_telegram_user_id, default_display_name or "Execution Owner"

    raise SystemExit(
        f"missing owner mapping for broker={broker}. "
        f"Provide --owner-map broker:telegram_id[:display_name] "
        f"or use --default-telegram-user-id."
    )


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Backfill broker_accounts.user_id and terminal_sessions.user_id for active execution accounts."
    )
    parser.add_argument(
        "--brokers",
        help="Comma-separated broker list. Defaults to vantage,startrader,bullwaves,ftmo,traderscale,fundednext",
    )
    parser.add_argument(
        "--platform",
        default="mt5",
        help="Target platform. Default: mt5",
    )
    parser.add_argument(
        "--labels-like",
        default="%Execution%",
        help="Label filter for execution accounts. Default: %%Execution%%",
    )
    parser.add_argument(
        "--owner-map",
        action="append",
        default=[],
        help="Repeatable mapping: broker:telegram_user_id[:display_name]",
    )
    parser.add_argument(
        "--default-telegram-user-id",
        type=int,
        help="Fallback Telegram user id for any broker missing in --owner-map",
    )
    parser.add_argument(
        "--default-display-name",
        help="Fallback display name when --default-telegram-user-id is used",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show planned changes without writing to DB",
    )
    args = parser.parse_args()

    brokers = _csv(args.brokers) or list(DEFAULT_BROKERS)

    owner_map: dict[str, tuple[int, str | None]] = {}
    for raw in args.owner_map:
        parts = raw.split(":", 2)
        if len(parts) < 2:
            raise SystemExit(f"invalid --owner-map entry: {raw}")
        broker = parts[0].strip().lower()
        telegram_user_id = int(parts[1].strip())
        display_name = parts[2].strip() if len(parts) >= 3 and parts[2].strip() else None
        owner_map[broker] = (telegram_user_id, display_name)

    with SessionLocal() as db:
        rows = db.execute(
            text(
                """
                SELECT
                  ba.account_id::text AS account_id,
                  ba.broker::text AS broker,
                  ba.platform::text AS platform,
                  ba.label,
                  ba.user_id::text AS broker_user_id,
                  ts.session_id::text AS session_id,
                  ts.terminal_name,
                  ts.user_id::text AS terminal_user_id,
                  ts.status
                FROM broker_accounts ba
                LEFT JOIN terminal_sessions ts
                  ON ts.broker_account_id = ba.account_id
                 AND ts.status IN ('starting', 'running')
                WHERE ba.is_active = true
                  AND ba.platform = :platform
                  AND ba.label LIKE :labels_like
                  AND ba.broker::text = ANY(:brokers)
                ORDER BY ba.broker, ba.label, ts.updated_at DESC NULLS LAST, ts.started_at DESC NULLS LAST
                """
            ),
            {
                "platform": args.platform,
                "labels_like": args.labels_like,
                "brokers": brokers,
            },
        ).mappings().all()

        if not rows:
            print({"updated_accounts": 0, "updated_sessions": 0, "matched_accounts": 0})
            return 0

        accounts_updated = 0
        sessions_updated = 0
        seen_accounts: set[str] = set()

        for row in rows:
            account_id = row["account_id"]
            broker = row["broker"]
            session_id = row["session_id"]

            telegram_user_id, display_name = _pick_identity(
                broker=broker,
                explicit_telegram_user_id=owner_map.get(broker, (None, None))[0],
                explicit_display_name=owner_map.get(broker, (None, None))[1],
                default_telegram_user_id=args.default_telegram_user_id,
                default_display_name=args.default_display_name,
            )

            user = get_or_create_user(
                telegram_user_id=telegram_user_id,
                display_name=display_name,
                role="user",
            )

            if account_id not in seen_accounts:
                seen_accounts.add(account_id)
                if row["broker_user_id"] != user.user_id:
                    accounts_updated += 1
                    print(
                        {
                            "action": "set_account_owner",
                            "broker": broker,
                            "account_id": account_id,
                            "label": row["label"],
                            "old_user_id": row["broker_user_id"],
                            "new_user_id": user.user_id,
                            "dry_run": args.dry_run,
                        }
                    )
                    if not args.dry_run:
                        db.execute(
                            text(
                                """
                                UPDATE broker_accounts
                                SET user_id = CAST(:user_id AS uuid)
                                WHERE account_id = CAST(:account_id AS uuid)
                                """
                            ),
                            {"account_id": account_id, "user_id": user.user_id},
                        )

            if session_id and row["terminal_user_id"] != user.user_id:
                sessions_updated += 1
                print(
                    {
                        "action": "set_terminal_owner",
                        "broker": broker,
                        "session_id": session_id,
                        "terminal_name": row["terminal_name"],
                        "old_user_id": row["terminal_user_id"],
                        "new_user_id": user.user_id,
                        "dry_run": args.dry_run,
                    }
                )
                if not args.dry_run:
                    db.execute(
                        text(
                            """
                            UPDATE terminal_sessions
                            SET user_id = CAST(:user_id AS uuid),
                                updated_at = now()
                            WHERE session_id = CAST(:session_id AS uuid)
                            """
                        ),
                        {"session_id": session_id, "user_id": user.user_id},
                    )

        if not args.dry_run:
            db.commit()

    print(
        {
            "updated_accounts": accounts_updated,
            "updated_sessions": sessions_updated,
            "matched_accounts": len(seen_accounts),
            "dry_run": args.dry_run,
        }
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
