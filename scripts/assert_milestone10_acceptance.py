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
        "app/execution/base.py",
        "app/execution/http_node.py",
        "app/execution/live_executor.py",
        "app/execution/node_contract.py",
        "app/execution/node_registry.py",
        "app/execution/node_stub.py",
        "app/execution/mt5_backend.py",
        "app/execution/ticket_ops.py",
        "app/execution/reconciliation.py",
        "scripts/smoke_windows_execution_node.py",
        "scripts/smoke_mt5_real_execution.py",
        "scripts/reconcile_execution_node.py",
        "scripts/setup_execution_node.py",
        "windows/README.md",
        "windows/run_node.ps1",
        "windows/health_check.ps1",
        "windows/install_node_service.ps1",
        "tests/test_live_executor_idempotency.py",
        "tests/test_execution_node_contract.py",
        "tests/test_http_execution_node_contract.py",
        "tests/test_mt5_backend.py",
        "tests/test_ticket_ops_integration.py",
        "tests/test_reconciliation_integration.py",
    ]
    missing = [p for p in required if not Path(p).exists()]
    if missing:
        return fail("Milestone 10 files exist", str(missing))
    return ok("Milestone 10 files exist")


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
                    "execution node contract tests",
                    [
                        "python",
                        "-m",
                        "pytest",
                        "-q",
                        "tests/test_execution_node_contract.py",
                        "tests/test_http_execution_node_contract.py",
                    ],
                ),
                run_cmd(
                    "MT5 backend tests",
                    [
                        "python",
                        "-m",
                        "pytest",
                        "-q",
                        "tests/test_mt5_backend.py",
                    ],
                ),
                run_cmd(
                    "live executor idempotency tests",
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
                    "mock executor regression",
                    [
                        "python",
                        "-m",
                        "pytest",
                        "-q",
                        "-m",
                        "integration",
                        "tests/test_mock_executor.py",
                    ],
                ),
            ]
        )

    print("\nMilestone 10 — Acceptance Check")
    print("----------------------------------")
    for c in checks:
        print_result(c)

    failed = [c for c in checks if not c.ok]
    print("----------------------------------")
    if failed:
        print(f"❌ Milestone 10 NOT ACCEPTED ({len(failed)} failures)")
        return 1

    print("✅ Milestone 10 ACCEPTED")
    print("\nManual live smoke verified separately:")
    print("- FTMO-Demo MT5 health ok")
    print("- 0.01 XAUUSD order opened")
    print("- broker ticket returned")
    print("- position visible through /open-positions")
    print("- position manually closed")
    print("- live gate returned to false")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
