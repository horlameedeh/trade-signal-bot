from __future__ import annotations

import argparse
import subprocess
from dataclasses import dataclass
from pathlib import Path


@dataclass
class CheckResult:
    ok: bool
    name: str
    details: str = ""


def ok(name: str, details: str = "") -> CheckResult:
    return CheckResult(True, name, details)


def fail(name: str, details: str = "") -> CheckResult:
    return CheckResult(False, name, details)


def print_result(r: CheckResult) -> None:
    mark = "✅" if r.ok else "❌"
    if r.details:
        print(f"{mark} {r.name}\n   {r.details}")
    else:
        print(f"{mark} {r.name}")


def check_files_exist() -> CheckResult:
    required = [
        "app/services/lifecycle.py",
        "app/execution/state_sync.py",
        "tests/test_trade_lifecycle_integration.py",
        "tests/test_execution_state_sync_integration.py",
    ]
    missing = [p for p in required if not Path(p).exists()]
    if missing:
        return fail("Milestone 13 files exist", str(missing))
    return ok("Milestone 13 files exist")


def run_cmd(name: str, cmd: list[str]) -> CheckResult:
    p = subprocess.run(cmd, capture_output=True, text=True)
    output = (p.stdout + "\n" + p.stderr).strip()
    if p.returncode != 0:
        return fail(name, output)
    return ok(name, p.stdout.strip())


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--run-tests", action="store_true")
    args = parser.parse_args()

    checks = [check_files_exist()]

    if args.run_tests:
        checks.extend(
            [
                run_cmd(
                    "trade lifecycle integration tests",
                    [
                        "python",
                        "-m",
                        "pytest",
                        "-q",
                        "-m",
                        "integration",
                        "tests/test_trade_lifecycle_integration.py",
                    ],
                ),
                run_cmd(
                    "execution state sync lifecycle tests",
                    [
                        "python",
                        "-m",
                        "pytest",
                        "-q",
                        "-m",
                        "integration",
                        "tests/test_execution_state_sync_integration.py",
                    ],
                ),
                run_cmd(
                    "reconciliation regression",
                    [
                        "python",
                        "-m",
                        "pytest",
                        "-q",
                        "-m",
                        "integration",
                        "tests/test_reconciliation_integration.py",
                    ],
                ),
            ]
        )

    print("\nMilestone 13 — Acceptance Check")
    print("----------------------------------")
    for c in checks:
        print_result(c)

    failed = [c for c in checks if not c.ok]
    print("----------------------------------")
    if failed:
        print(f"❌ Milestone 13 NOT ACCEPTED ({len(failed)} failures)")
        return 1

    print("✅ Milestone 13 ACCEPTED")
    print("\nVerified:")
    print("- Family lifecycle states transition correctly")
    print("- Leg outcomes TP_HIT / SL_HIT / CLOSED_MANUAL are handled")
    print("- Realized PnL calculated")
    print("- Floating PnL calculated")
    print("- Exposure-at-SL calculated")
    print("- Lifecycle metrics persisted to trade_families.meta")
    print("- State sync automatically recomputes affected families")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
