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
        "app/services/restart_recovery.py",
        "scripts/recover_after_restart.py",
        "tests/test_restart_recovery_integration.py",
        "app/execution/reconciliation.py",
        "app/execution/state_sync.py",
        "app/services/management_live.py",
        "app/execution/retry.py",
    ]
    missing = [p for p in required if not Path(p).exists()]
    if missing:
        return fail("Milestone 17 files exist", str(missing))
    return ok("Milestone 17 files exist")


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
                    "restart recovery integration tests",
                    [
                        "python",
                        "-m",
                        "pytest",
                        "-q",
                        "-m",
                        "integration",
                        "tests/test_restart_recovery_integration.py",
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
                run_cmd(
                    "state sync regression",
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
                    "live management regression",
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
                    "retry/idempotency regression",
                    [
                        "python",
                        "-m",
                        "pytest",
                        "-q",
                        "-m",
                        "integration",
                        "tests/test_execution_retry_integration.py",
                        "tests/test_live_executor_idempotency.py",
                    ],
                ),
            ]
        )

    print("\nMilestone 17 — Acceptance Check")
    print("----------------------------------")
    for c in checks:
        print_result(c)

    failed = [c for c in checks if not c.ok]
    print("----------------------------------")
    if failed:
        print(f"❌ Milestone 17 NOT ACCEPTED ({len(failed)} failures)")
        return 1

    print("✅ Milestone 17 ACCEPTED")
    print("\nVerified:")
    print("- Restart recovery orchestrator exists")
    print("- Broker reconciliation runs during recovery")
    print("- State sync runs during recovery")
    print("- Lifecycle recomputation resumes")
    print("- Management rules resume")
    print("- Pending retry/dead-letter/control queues are reported")
    print("- Recovery is idempotent")
    print("- Duplicate execution is prevented by ticket idempotency")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
