from __future__ import annotations

import subprocess
import sys
from pathlib import Path

from sqlalchemy import text

from app.db.session import SessionLocal


TESTS = [
    "tests/test_terminal_sessions.py",
]


def run(cmd: list[str]) -> None:
    print("+", " ".join(cmd))
    subprocess.run(cmd, check=True)


def check_files() -> None:
    required = [
        "alembic/versions/89f12e0ba78a_add_terminal_sessions.py",
        "app/execution/terminal_sessions.py",
        "tests/test_terminal_sessions.py",
        "scripts/assert_milestone27_phase1.py",
    ]

    missing = [path for path in required if not Path(path).exists()]
    if missing:
        raise SystemExit(f"missing required files: {missing}")

    print("✅ Milestone 27 Phase 1 files exist")


def check_db() -> None:
    with SessionLocal() as db:
        table_exists = db.execute(
            text(
                """
                SELECT EXISTS (
                  SELECT 1
                  FROM information_schema.tables
                  WHERE table_schema = 'public'
                    AND table_name = 'terminal_sessions'
                )
                """
            )
        ).scalar()

        if not table_exists:
            raise SystemExit("missing DB table: terminal_sessions")

    print("✅ Terminal sessions DB checks passed")


def main() -> int:
    print("\nMilestone 27 Phase 1 — Terminal Sessions Acceptance")
    print("---------------------------------------------------")

    check_files()
    check_db()
    run([sys.executable, "-m", "pytest", "-q", *TESTS])

    print("---------------------------------------------------")
    print("✅ Milestone 27 Phase 1 ACCEPTED")
    print("\nVerified:")
    print("- terminal_sessions migration exists")
    print("- terminal session routing module exists")
    print("- terminal_sessions table exists in the database")
    print("- terminal sessions can be created and closed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())