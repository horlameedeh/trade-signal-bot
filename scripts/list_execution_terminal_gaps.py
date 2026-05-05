from __future__ import annotations

import argparse
import sys
from pathlib import Path

from sqlalchemy import text

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from app.db.session import SessionLocal


def main() -> int:
    parser = argparse.ArgumentParser(
        description="List active execution accounts and show whether they host a running terminal session."
    )
    parser.add_argument(
        "--labels-like",
        default="%Execution%",
        help="Label filter for execution accounts. Default: %%Execution%%",
    )
    args = parser.parse_args()

    with SessionLocal() as db:
        rows = db.execute(
            text(
                """
                SELECT
                  ba.account_id::text AS account_id,
                  ba.broker::text AS broker,
                  ba.platform::text AS platform,
                  ba.kind::text AS kind,
                  ba.label,
                  ba.user_id::text AS broker_user_id,
                  ts.session_id::text AS session_id,
                  ts.terminal_name,
                  ts.user_id::text AS terminal_user_id,
                  ts.status,
                  CASE
                    WHEN ts.session_id IS NULL THEN 'missing_running_terminal'
                    WHEN ts.user_id IS NULL THEN 'missing_terminal_owner'
                    WHEN ts.user_id <> ba.user_id THEN 'terminal_session_user_mismatch'
                    ELSE NULL
                  END AS issue
                FROM broker_accounts ba
                LEFT JOIN terminal_sessions ts
                  ON ts.broker_account_id = ba.account_id
                 AND ts.status IN ('starting', 'running')
                WHERE ba.is_active = true
                  AND ba.label LIKE :labels_like
                ORDER BY ba.broker, ba.label, ts.updated_at DESC NULLS LAST, ts.started_at DESC NULLS LAST
                """
            ),
            {"labels_like": args.labels_like},
        ).mappings().all()

    print({"active_execution_accounts": len(rows)})
    for row in rows:
        print(dict(row))

    issues = [dict(row) for row in rows if row["issue"] is not None]
    print({"accounts_with_issues": len(issues)})
    return 0 if not issues else 1


if __name__ == "__main__":
    raise SystemExit(main())