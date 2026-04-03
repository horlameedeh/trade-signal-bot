from __future__ import annotations

import argparse
import subprocess
import sys
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
        "app/decision/models.py",
        "app/decision/engine.py",
        "app/services/approvals.py",
        "app/services/timeouts.py",
        "app/services/decision_flow.py",
        "app/services/approval_callbacks.py",
        "tests/test_decision_engine.py",
        "tests/test_approvals.py",
        "tests/test_timeouts.py",
        "tests/test_decision_integration.py",
        "tests/test_approval_callbacks.py",
    ]
    missing = [p for p in required if not Path(p).exists()]
    if missing:
        return fail("Milestone 4 files exist", str(missing))
    return ok("Milestone 4 files exist")


def run_cmd(name: str, cmd: list[str]) -> CheckResult:
    p = subprocess.run(cmd, capture_output=True, text=True)
    if p.returncode != 0:
        return fail(name, (p.stdout + "\n" + p.stderr).strip())
    return ok(name, p.stdout.strip())


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--run-tests", action="store_true")
    args = ap.parse_args()

    checks = [check_files_exist()]

    if args.run_tests:
        checks.extend(
            [
                run_cmd(
                    "decision engine unit tests",
                    [
                        sys.executable,
                        "-m",
                        "pytest",
                        "-q",
                        "tests/test_decision_engine.py",
                        "tests/test_timeouts.py",
                    ],
                ),
                run_cmd(
                    "decision/approval integration tests",
                    [
                        sys.executable,
                        "-m",
                        "pytest",
                        "-q",
                        "-m",
                        "integration",
                        "tests/test_approvals.py",
                        "tests/test_decision_integration.py",
                        "tests/test_approval_callbacks.py",
                    ],
                ),
            ]
        )

    print("\nMilestone 4 — Acceptance Check")
    print("----------------------------------")
    for c in checks:
        print_result(c)

    failed = [c for c in checks if not c.ok]
    print("----------------------------------")
    if failed:
        print(f"❌ Milestone 4 NOT ACCEPTED ({len(failed)} failures)")
        return 1

    print("✅ Milestone 4 ACCEPTED")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
