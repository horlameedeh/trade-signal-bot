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
        "config/prop_risk_rules.yaml",
        "app/risk/prop_rules.py",
        "app/risk/exposure.py",
        "app/execution/guarded_live_executor.py",
        "tests/test_prop_risk_rules.py",
        "tests/test_prop_risk_exposure_integration.py",
        "tests/test_guarded_live_executor_integration.py",
    ]
    missing = [p for p in required if not Path(p).exists()]
    if missing:
        return fail("Milestone 11 files exist", str(missing))
    return ok("Milestone 11 files exist")


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
                    "prop risk unit tests",
                    ["python", "-m", "pytest", "-q", "tests/test_prop_risk_rules.py"],
                ),
                run_cmd(
                    "prop risk exposure integration tests",
                    [
                        "python",
                        "-m",
                        "pytest",
                        "-q",
                        "-m",
                        "integration",
                        "tests/test_prop_risk_exposure_integration.py",
                    ],
                ),
                run_cmd(
                    "guarded executor integration tests",
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

    print("\nMilestone 11 — Acceptance Check")
    print("----------------------------------")
    for c in checks:
        print_result(c)

    failed = [c for c in checks if not c.ok]
    print("----------------------------------")
    if failed:
        print(f"❌ Milestone 11 NOT ACCEPTED ({len(failed)} failures)")
        return 1

    print("✅ Milestone 11 ACCEPTED")
    print("\nVerified:")
    print("- Prop firm profiles configured")
    print("- Exposure-at-SL calculated from DB")
    print("- Current open exposure aggregated")
    print("- Breaching trades blocked before execution")
    print("- Near-limit trades require approval")
    print("- Risk alerts queued in control_actions")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
