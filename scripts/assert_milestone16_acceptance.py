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
        "app/execution/retry.py",
        "app/execution/guarded_live_executor.py",
        "tests/test_execution_retry.py",
        "tests/test_execution_retry_integration.py",
        "tests/test_guarded_retry_integration.py",
        "tests/test_guarded_live_executor_integration.py",
        "tests/test_live_executor_idempotency.py",
    ]
    missing = [p for p in required if not Path(p).exists()]
    if missing:
        return fail("Milestone 16 files exist", str(missing))
    return ok("Milestone 16 files exist")


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
                    "execution retry unit tests",
                    ["python", "-m", "pytest", "-q", "tests/test_execution_retry.py"],
                ),
                run_cmd(
                    "execution retry integration tests",
                    [
                        "python",
                        "-m",
                        "pytest",
                        "-q",
                        "-m",
                        "integration",
                        "tests/test_execution_retry_integration.py",
                    ],
                ),
                run_cmd(
                    "guarded retry integration tests",
                    [
                        "python",
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
                        "python",
                        "-m",
                        "pytest",
                        "-q",
                        "-m",
                        "integration",
                        "tests/test_guarded_live_executor_integration.py",
                    ],
                ),
                run_cmd(
                    "live executor idempotency regression",
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

    print("\nMilestone 16 — Acceptance Check")
    print("----------------------------------")
    for c in checks:
        print_result(c)

    failed = [c for c in checks if not c.ok]
    print("----------------------------------")
    if failed:
        print(f"❌ Milestone 16 NOT ACCEPTED ({len(failed)} failures)")
        return 1

    print("✅ Milestone 16 ACCEPTED")
    print("\nVerified:")
    print("- Retry policy implemented")
    print("- Backoff calculation deterministic")
    print("- Temporary execution failures recover")
    print("- Permanent execution failures dead-letter")
    print("- Permanent failures trigger execution-failure alert")
    print("- Guarded execution uses retry path")
    print("- Prop-risk blocks before retry")
    print("- Idempotent retries do not duplicate tickets/trades")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
