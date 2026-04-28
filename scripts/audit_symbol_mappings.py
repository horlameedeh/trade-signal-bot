from __future__ import annotations

import argparse
import json
from collections import defaultdict
from dataclasses import asdict, dataclass

from sqlalchemy import text

from app.db.session import SessionLocal
from app.services.symbol_aliases import resolve_broker_symbol


@dataclass(frozen=True)
class MappingCheck:
    canonical_symbol: str
    broker: str
    platform: str
    resolved_symbol: str | None
    found: bool
    blocked: bool
    reason: str


def _load_canonical_symbols(limit_to_openish: bool = False) -> list[str]:
    with SessionLocal() as db:
        if limit_to_openish:
            rows = db.execute(
                text(
                    """
                    SELECT DISTINCT ti.symbol_canonical
                    FROM trade_intents ti
                    JOIN trade_families tf ON tf.intent_id = ti.intent_id
                    WHERE ti.symbol_canonical IS NOT NULL
                      AND tf.state IN ('OPEN', 'PENDING_UPDATE', 'PENDING_APPROVAL', 'CANDIDATE')
                    ORDER BY ti.symbol_canonical
                    """
                )
            ).scalars().all()
        else:
            rows = db.execute(
                text(
                    """
                    SELECT DISTINCT symbol_canonical
                    FROM trade_intents
                    WHERE symbol_canonical IS NOT NULL
                    ORDER BY symbol_canonical
                    """
                )
            ).scalars().all()

    return [str(x) for x in rows if x]


def _load_broker_platforms(active_only: bool = True) -> list[tuple[str, str]]:
    with SessionLocal() as db:
        if active_only:
            rows = db.execute(
                text(
                    """
                    SELECT DISTINCT broker, platform
                    FROM broker_accounts
                    WHERE is_active = true
                    ORDER BY broker, platform
                    """
                )
            ).all()
        else:
            rows = db.execute(
                text(
                    """
                    SELECT DISTINCT broker, platform
                    FROM broker_accounts
                    ORDER BY broker, platform
                    """
                )
            ).all()

    return [(str(b), str(p)) for b, p in rows if b and p]


def run_audit(*, active_only: bool, openish_only: bool) -> list[MappingCheck]:
    symbols = _load_canonical_symbols(limit_to_openish=openish_only)
    broker_platforms = _load_broker_platforms(active_only=active_only)

    checks: list[MappingCheck] = []
    for canonical_symbol in symbols:
        for broker, platform in broker_platforms:
            result = resolve_broker_symbol(
                canonical_symbol=canonical_symbol,
                broker=broker,
                platform=platform,
            )
            checks.append(
                MappingCheck(
                    canonical_symbol=canonical_symbol,
                    broker=broker,
                    platform=platform,
                    resolved_symbol=result.resolved_symbol,
                    found=result.found,
                    blocked=result.blocked,
                    reason=result.reason,
                )
            )
    return checks


def print_report(checks: list[MappingCheck]) -> int:
    total = len(checks)
    ok = sum(1 for c in checks if c.found and not c.blocked)
    missing = [c for c in checks if c.blocked]

    print("Symbol Mapping Audit")
    print("--------------------")
    print(f"Total combinations checked: {total}")
    print(f"Resolved successfully:      {ok}")
    print(f"Blocked / missing:          {len(missing)}")

    by_broker: dict[str, dict[str, int]] = defaultdict(lambda: {"ok": 0, "blocked": 0})
    for c in checks:
        if c.blocked:
            by_broker[c.broker]["blocked"] += 1
        else:
            by_broker[c.broker]["ok"] += 1

    if by_broker:
        print("\nBy broker:")
        for broker in sorted(by_broker):
            stats = by_broker[broker]
            print(f"  {broker}: ok={stats['ok']} blocked={stats['blocked']}")

    if missing:
        print("\nMissing / blocked mappings:")
        for c in sorted(missing, key=lambda x: (x.broker, x.platform, x.canonical_symbol)):
            print(
                f"  broker={c.broker:<12} platform={c.platform:<4} "
                f"symbol={c.canonical_symbol:<10} reason={c.reason}"
            )

    if not missing:
        print("\n✅ No missing mappings found.")

    return 1 if missing else 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Audit canonical symbol mappings against broker/platform profiles.")
    parser.add_argument(
        "--all-accounts",
        action="store_true",
        help="Include inactive broker_accounts too (default: active accounts only).",
    )
    parser.add_argument(
        "--openish-only",
        action="store_true",
        help="Only audit symbols currently used by open/pending trade families.",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Print full results as JSON.",
    )
    args = parser.parse_args()

    checks = run_audit(
        active_only=not args.all_accounts,
        openish_only=args.openish_only,
    )

    if args.json:
        print(json.dumps([asdict(c) for c in checks], indent=2))
        return 0

    return print_report(checks)


if __name__ == "__main__":
    raise SystemExit(main())
