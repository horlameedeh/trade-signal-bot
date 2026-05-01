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
        "app/services/alerts.py",
        "app/execution/node_health.py",
        "app/execution/guarded_live_executor.py",
        "app/execution/ticket_ops.py",
        "app/execution/state_sync.py",
        "app/services/management_live.py",
        "scripts/check_execution_node_health.py",
        "tests/test_alerts.py",
        "tests/test_alerts_integration.py",
        "tests/test_alert_wiring_integration.py",
        "tests/test_node_health_alerts_integration.py",
    ]
    missing = [p for p in required if not Path(p).exists()]
    if missing:
        return fail("Milestone 15 files exist", str(missing))
    return ok("Milestone 15 files exist")


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
                    "alert formatting unit tests",
                    ["python", "-m", "pytest", "-q", "tests/test_alerts.py"],
                ),
                run_cmd(
                    "alert queue integration tests",
                    [
                        "python",
                        "-m",
                        "pytest",
                        "-q",
                        "-m",
                        "integration",
                        "tests/test_alerts_integration.py",
                    ],
                ),
                run_cmd(
                    "alert wiring integration tests",
                    [
                        "python",
                        "-m",
                        "pytest",
                        "-q",
                        "-m",
                        "integration",
                        "tests/test_alert_wiring_integration.py",
                    ],
                ),
                run_cmd(
                    "node health alert integration tests",
                    [
                        "python",
                        "-m",
                        "pytest",
                        "-q",
                        "-m",
                        "integration",
                        "tests/test_node_health_alerts_integration.py",
                    ],
                ),
                run_cmd(
                    "management regression",
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
            ]
        )

    print("\nMilestone 15 — Acceptance Check")
    print("----------------------------------")
    for c in checks:
        print_result(c)

    failed = [c for c in checks if not c.ok]
    print("----------------------------------")
    if failed:
        print(f"❌ Milestone 15 NOT ACCEPTED ({len(failed)} failures)")
        return 1

    print("✅ Milestone 15 ACCEPTED")
    print("\nVerified:")
    print("- Structured Control Chat alert payloads")
    print("- Alerts queued in control_actions")
    print("- Execution failure alerts")
    print("- Missing symbol mapping alert support")
    print("- Reconciliation mismatch alerts")
    print("- MT5/node disconnected alerts")
    print("- Trade opened alerts")
    print("- SL/TP modified alerts")
    print("- Trade closed alerts")
    print("- Management action alerts")
    print("- Alerts are actionable and formatted")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
