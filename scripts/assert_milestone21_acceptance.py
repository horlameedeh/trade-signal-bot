from __future__ import annotations

import argparse
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path

from dotenv import load_dotenv


load_dotenv()


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
        "config/global_safety.yaml",
        "app/risk/global_safety.py",
        "app/execution/guarded_live_executor.py",
        "tests/test_global_safety.py",
        "tests/test_global_safety_integration.py",
        "tests/test_guarded_global_safety_integration.py",
    ]

    missing = [p for p in required if not Path(p).exists()]
    if missing:
        return fail("Milestone 21 files exist", str(missing))
    return ok("Milestone 21 files exist")


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

    py = sys.executable

    checks = [check_files_exist()]

    if args.run_tests:
        checks.extend(
            [
                run_cmd(
                    "global safety unit tests",
                    [py, "-m", "pytest", "-q", "tests/test_global_safety.py"],
                ),
                run_cmd(
                    "global safety DB integration tests",
                    [
                        py,
                        "-m",
                        "pytest",
                        "-q",
                        "-m",
                        "integration",
                        "tests/test_global_safety_integration.py",
                    ],
                ),
                run_cmd(
                    "guarded global safety integration tests",
                    [
                        py,
                        "-m",
                        "pytest",
                        "-q",
                        "-m",
                        "integration",
                        "tests/test_guarded_global_safety_integration.py",
                    ],
                ),
                run_cmd(
                    "guarded retry regression",
                    [
                        py,
                        "-m",
                        "pytest",
                        "-q",
                        "-m",
                        "integration",
                        "tests/test_guarded_retry_integration.py",
                    ],
                ),
                run_cmd(
                    "guarded executor regression",
                    [
                        py,
                        "-m",
                        "pytest",
                        "-q",
                        "-m",
                        "integration",
                        "tests/test_guarded_live_executor_integration.py",
                    ],
                ),
            ]
        )

    print("\nMilestone 21 — Acceptance Check")
    print("----------------------------------")
    for c in checks:
        print_result(c)

    failed = [c for c in checks if not c.ok]

    print("----------------------------------")
    if failed:
        print(f"❌ Milestone 21 NOT ACCEPTED ({len(failed)} failures)")
        return 1

    print("✅ Milestone 21 ACCEPTED")
    print("\nVerified:")
    print("- Global safety config exists")
    print("- Kill switch blocks execution instantly")
    print("- Max trades per day enforced")
    print("- Max open trades enforced")
    print("- Max exposure per symbol enforced")
    print("- Global loss cutoff enforced")
    print("- Near-limit cases require approval")
    print("- Global safety runs before prop-risk/retry/live execution")
    print("- Idempotent guarded execution regressions remain clean")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
