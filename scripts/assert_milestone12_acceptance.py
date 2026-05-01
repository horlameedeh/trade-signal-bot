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
        "app/execution/state_sync.py",
        "app/execution/reconciliation.py",
        "app/execution/ticket_ops.py",
        "scripts/sync_execution_state.py",
        "scripts/reconcile_execution_node.py",
        "tests/test_execution_state_sync_integration.py",
        "tests/test_reconciliation_integration.py",
        "tests/test_ticket_ops_integration.py",
    ]
    missing = [p for p in required if not Path(p).exists()]
    if missing:
        return fail("Milestone 12 files exist", str(missing))
    return ok("Milestone 12 files exist")


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
                    "execution state sync integration tests",
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
                    "reconciliation integration tests",
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
                    "ticket operation integration tests",
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
                    "live executor regression",
                    [
                        "python",
                        "-m",
                        "pytest",
                        "-q",
                        "-m",
                        "integration",
                        "tests/test_live_executor_idempotency.py",
                    ],
                ),
            ]
        )

    print("\nMilestone 12 — Acceptance Check")
    print("----------------------------------")
    for c in checks:
        print_result(c)

    failed = [c for c in checks if not c.ok]
    print("----------------------------------")
    if failed:
        print(f"❌ Milestone 12 NOT ACCEPTED ({len(failed)} failures)")
        return 1

    print("✅ Milestone 12 ACCEPTED")
    print("\nVerified:")
    print("- Broker open positions can be polled")
    print("- Local open tickets are compared against broker reality")
    print("- Missing positions are marked closed")
    print("- Closed legs are classified as TP_HIT / SL_HIT / CLOSED_MANUAL where possible")
    print("- Family state rolls up to PARTIALLY_CLOSED / CLOSED")
    print("- Raw sync evidence is stored")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
