from __future__ import annotations

from dataclasses import dataclass
from typing import Optional

from sqlalchemy import text

from app.db.session import SessionLocal


@dataclass(frozen=True)
class MatchResult:
    family_id: Optional[str]
    requires_selection: bool
    candidates: list[str]


def match_trade_family_for_update(
    *,
    provider: str,
    symbol: str,
    side: str,
    window_minutes: int = 60,
) -> MatchResult:
    """
    Matching priority:
    1) PENDING_UPDATE
    2) OPEN
    """

    with SessionLocal() as db:
        # 1) Try PENDING_UPDATE
        pending = db.execute(
            text(
                """
                SELECT family_id::text
                FROM trade_families
                WHERE provider = :provider
                  AND symbol_canonical = :symbol
                  AND side = :side
                  AND state = 'PENDING_UPDATE'
                  AND created_at >= now() - (:window || ' minutes')::interval
                ORDER BY created_at DESC
                """
            ),
            {
                "provider": provider,
                "symbol": symbol,
                "side": side,
                "window": window_minutes,
            },
        ).scalars().all()

        if len(pending) == 1:
            return MatchResult(family_id=pending[0], requires_selection=False, candidates=[])

        if len(pending) > 1:
            return MatchResult(family_id=None, requires_selection=True, candidates=pending)

        # 2) Try OPEN
        open_rows = db.execute(
            text(
                """
                SELECT family_id::text
                FROM trade_families
                WHERE provider = :provider
                  AND symbol_canonical = :symbol
                  AND side = :side
                  AND state = 'OPEN'
                  AND created_at >= now() - (:window || ' minutes')::interval
                ORDER BY created_at DESC
                """
            ),
            {
                "provider": provider,
                "symbol": symbol,
                "side": side,
                "window": window_minutes,
            },
        ).scalars().all()

        if len(open_rows) == 1:
            return MatchResult(family_id=open_rows[0], requires_selection=False, candidates=[])

        if len(open_rows) > 1:
            return MatchResult(family_id=None, requires_selection=True, candidates=open_rows)

    return MatchResult(family_id=None, requires_selection=False, candidates=[])
