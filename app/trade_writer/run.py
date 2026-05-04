from __future__ import annotations

import argparse

from sqlalchemy import text

from app.db.session import SessionLocal
from app.services.trade_writer import create_trade_family_and_legs


def _list_pending_source_messages(*, limit: int) -> list[dict]:
    with SessionLocal() as db:
        rows = db.execute(
            text(
                """
                SELECT
                  ti.source_msg_pk::text AS source_msg_pk,
                  ti.provider,
                  ti.symbol_canonical,
                  ti.side::text AS side,
                  ti.entry_price::text AS entry_price,
                  ti.sl_price::text AS sl_price,
                  tm.created_at
                FROM trade_intents ti
                JOIN telegram_messages tm ON tm.msg_pk = ti.source_msg_pk
                LEFT JOIN trade_families tf ON tf.source_msg_pk = ti.source_msg_pk
                WHERE tf.family_id IS NULL
                ORDER BY tm.created_at DESC
                LIMIT :limit
                """
            ),
            {"limit": limit},
        ).mappings().all()

    return [dict(row) for row in rows]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("source_msg_pk", nargs="?", help="Source telegram message UUID to build a trade family for")
    parser.add_argument("--dry-run", action="store_true", help="List pending trade intents without creating families")
    parser.add_argument("--limit", type=int, default=20, help="Maximum rows to show in dry-run mode")
    args = parser.parse_args()

    if args.dry_run:
        pending = _list_pending_source_messages(limit=args.limit)
        print(f"pending_trade_intents={len(pending)}")
        for row in pending:
            print(
                f"{row['source_msg_pk']} provider={row['provider']} "
                f"symbol={row['symbol_canonical']} side={row['side']} "
                f"entry={row['entry_price']} sl={row['sl_price']}"
            )
        return 0

    if not args.source_msg_pk:
        parser.error("source_msg_pk is required unless --dry-run is specified")

    result = create_trade_family_and_legs(source_msg_pk=args.source_msg_pk)
    print(result)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())