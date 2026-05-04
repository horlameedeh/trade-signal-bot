from __future__ import annotations

import subprocess
import sys
from pathlib import Path

from sqlalchemy import text

from app.db.session import SessionLocal
from tests.helpers.account_cleanup import deactivate_named_test_accounts


TESTS = [
    "tests/test_account_routing_guard.py",
    "tests/test_global_safety.py",
    "tests/test_guarded_global_safety_integration.py",
    "tests/test_prop_risk_rules.py",
    "tests/test_prop_risk_exposure_integration.py",
]


def run(cmd: list[str]) -> None:
    print("+", " ".join(cmd))
    subprocess.run(cmd, check=True)


def check_db() -> None:
    with SessionLocal() as db:
        deactivate_named_test_accounts(db)

        dupes = db.execute(
            text(
                """
                SELECT broker::text, platform::text, COUNT(*) AS active_accounts
                FROM broker_accounts
                WHERE is_active = true
                GROUP BY broker, platform
                HAVING COUNT(*) > 1
                """
            )
        ).mappings().all()

        if dupes:
            raise SystemExit(f"duplicate active execution accounts found: {dupes}")

        index_exists = db.execute(
            text(
                """
                SELECT EXISTS (
                  SELECT 1
                  FROM pg_indexes
                  WHERE indexname = 'uniq_active_execution_account'
                )
                """
            )
        ).scalar()

        if not index_exists:
            raise SystemExit("missing DB index: uniq_active_execution_account")

    print("✅ DB routing integrity checks passed")


def check_files() -> None:
    required = [
        "config/global_safety.yaml",
        "config/prop_risk_rules.yaml",
        "app/risk/global_safety.py",
        "app/risk/prop_rules.py",
        "app/risk/exposure.py",
        "app/execution/guarded_live_executor.py",
        "tests/helpers/account_cleanup.py",
    ]

    missing = [path for path in required if not Path(path).exists()]
    if missing:
        raise SystemExit(f"missing required files: {missing}")

    print("✅ Milestone 26 files exist")


def main() -> int:
    print("\nMilestone 26 — Live Safeguards Acceptance")
    print("----------------------------------------")

    check_files()
    check_db()
    run([sys.executable, "-m", "pytest", "-q", *TESTS])

    print("----------------------------------------")
    print("✅ Milestone 26 ACCEPTED")
    print("\nVerified:")
    print("- One active account per broker/platform is enforced")
    print("- Runtime routing ambiguity guard is tested")
    print("- Kill switch guard is tested")
    print("- Lot cap safeguards are tested")
    print("- Daily loss and drawdown guards are tested")
    print("- Blocked-trade logging/control actions are tested")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())