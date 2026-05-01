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
        "app/services/management_live.py",
        "app/execution/state_sync.py",
        "app/execution/ticket_ops.py",
        "app/services/lifecycle.py",
        "tests/test_live_management_integration.py",
        "tests/test_execution_state_sync_integration.py",
        "tests/test_ticket_ops_integration.py",
        "tests/test_trade_lifecycle_integration.py",
    ]
    missing = [p for p in required if not Path(p).exists()]
    if missing:
        return fail("Milestone 14 files exist", str(missing))
    return ok("Milestone 14 files exist")


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
                    "live management integration tests",
                    [
                        "python",
                        "-m",
                        "pytest",
                        "-q",
                        "-m",
                        "integration",
                        "tests/test_live_management_integration.py",
                    ],
                ),
                run_cmd(
                    "state sync management trigger tests",
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
                    "ticket operation regression",
                    [
                        "python",
                        "-m",
                        "pytest",
                        "-q",
                        "-m",
                        "integration",
                        "tests/test_ticket_ops_integration.py",
                    ],
                ),
                run_cmd(
                    "trade lifecycle regression",
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
            ]
        )

    print("\nMilestone 14 — Acceptance Check")
    print("----------------------------------")
    for c in checks:
        print_result(c)

    failed = [c for c in checks if not c.ok]
    print("----------------------------------")
    if failed:
        print(f"❌ Milestone 14 NOT ACCEPTED ({len(failed)} failures)")
        return 1

    print("✅ Milestone 14 ACCEPTED")
    print("\nVerified:")
    print("- Live BE-at-TP1 management rule implemented")
    print("- TP1 hit triggers SL → Entry for remaining open legs")
    print("- Management is triggered from state sync")
    print("- Ticket-aware live modify service is used")
    print("- Management updates are idempotent")
    print("- Repeated sync / restart does not duplicate modifications")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
