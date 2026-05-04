from __future__ import annotations

import subprocess
import sys
from pathlib import Path

from sqlalchemy import text

from app.db.session import SessionLocal

REQUIRED_FILES = [
    "app/execution/terminal_sessions.py",
    "tests/test_terminal_session_routing.py",
    "scripts/setup_terminal_session.py",
]


def check_files() -> None:
    missing = [f for f in REQUIRED_FILES if not Path(f).exists()]
    if missing:
        raise SystemExit(f"missing files: {missing}")
    print("✅ Milestone 27 Phase 2 files exist")


def check_db_columns() -> None:
    with SessionLocal() as db:
        cols = {
            r[0]
            for r in db.execute(
                text(
                    """
                    SELECT column_name
                    FROM information_schema.columns
                    WHERE table_name = 'terminal_sessions'
                    """
                )
            ).all()
        }

    required = {
        "session_id",
        "broker_account_id",
        "terminal_name",
        "terminal_path",
        "data_dir",
        "port",
        "status",
        "last_heartbeat",
    }
    missing = sorted(required - cols)
    if missing:
        raise SystemExit(f"terminal_sessions missing columns: {missing}")
    print("✅ Terminal sessions routing columns exist")


def run_tests() -> None:
    cmd = [
        sys.executable,
        "-m",
        "pytest",
        "-q",
        "tests/test_terminal_sessions.py",
        "tests/test_terminal_session_routing.py",
        "tests/test_account_routing_guard.py",
    ]
    print("+", " ".join(cmd))
    subprocess.run(cmd, check=True)


def main() -> int:
    print("\nMilestone 27 Phase 2 — Terminal Routing Acceptance")
    print("--------------------------------------------------")
    check_files()
    check_db_columns()
    run_tests()
    print("--------------------------------------------------")
    print("✅ Milestone 27 Phase 2 ACCEPTED\n")
    print("Verified:")
    print("- Active broker accounts can resolve to dedicated terminal sessions")
    print("- Missing terminal sessions fail safely")
    print("- Ambiguous terminal sessions fail safely")
    print("- Closed terminal sessions are ignored")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())