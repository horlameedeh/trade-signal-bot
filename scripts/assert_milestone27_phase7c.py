from __future__ import annotations

import subprocess
import sys
from pathlib import Path

from sqlalchemy import text

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from app.db.session import SessionLocal


REQUIRED_FILES = [
    "scripts/backfill_execution_account_owners.py",
    "scripts/assert_milestone27_phase7c.py",
    "tests/test_execution_owner_backfill.py",
]


def _require_files() -> None:
    missing = [p for p in REQUIRED_FILES if not Path(p).exists()]
    if missing:
        raise SystemExit(f"missing files: {missing}")


def _check_db_shape() -> None:
    with SessionLocal() as db:
        rows = db.execute(
            text(
                """
                SELECT
                  ba.broker::text AS broker,
                  ba.label,
                  ba.user_id::text AS broker_user_id,
                  ts.user_id::text AS terminal_user_id
                FROM broker_accounts ba
                LEFT JOIN terminal_sessions ts
                  ON ts.broker_account_id = ba.account_id
                 AND ts.status IN ('starting', 'running')
                WHERE ba.is_active = true
                  AND ba.platform = 'mt5'
                  AND ba.label LIKE '%Execution%'
                ORDER BY ba.broker, ba.label
                """
            )
        ).mappings().all()

    if not rows:
        raise SystemExit("no active execution accounts found")

    print("✅ Active execution ownership view loaded")
    for row in rows:
        print(dict(row))


def main() -> int:
    print("Milestone 27 Phase 7C — Production Ownership Backfill Acceptance")
    print("----------------------------------------------------------------")
    _require_files()
    print("✅ Phase 7C files exist")
    _check_db_shape()

    cmd = [
        sys.executable,
        "-m",
        "pytest",
        "-q",
        "tests/test_execution_owner_backfill.py",
        "tests/test_terminal_sessions.py",
        "tests/test_terminal_session_routing.py",
        "tests/test_guarded_terminal_routing_integration.py",
    ]
    print("+", " ".join(cmd))
    subprocess.run(cmd, check=True)
    print("----------------------------------------------------------------")
    print("✅ Milestone 27 Phase 7C ACCEPTED")
    print()
    print("Verified:")
    print("- Active execution account owners can be backfilled")
    print("- Running terminal session owners can be backfilled")
    print("- Owner-aware routing remains enforced")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
