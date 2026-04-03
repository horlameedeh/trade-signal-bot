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
        "app/services/trade_writer.py",
        "app/services/update_matcher.py",
        "app/services/update_applier.py",
        "app/services/management.py",
        "app/services/edit_handler.py",
        "tests/test_trade_writer.py",
        "tests/test_update_matcher.py",
        "tests/test_update_applier.py",
        "tests/test_management_rules.py",
        "tests/test_edit_handling.py",
        "scripts/smoke_milestone5_flow.py",
        "scripts/cleanup_milestone5_smoke.py",
    ]
    missing = [p for p in required if not Path(p).exists()]
    if missing:
        return fail("Milestone 5 files exist", str(missing))
    return ok("Milestone 5 files exist")


def run_cmd(name: str, cmd: list[str]) -> CheckResult:
    p = subprocess.run(cmd, capture_output=True, text=True)
    if p.returncode != 0:
        return fail(name, (p.stdout + "\n" + p.stderr).strip())
    return ok(name, p.stdout.strip())


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--run-tests", action="store_true")
    ap.add_argument("--run-smoke", action="store_true")
    args = ap.parse_args()

    checks = [check_files_exist()]

    if args.run_tests:
        checks.extend(
            [
                run_cmd(
                    "trade writer integration tests",
                    ["pytest", "-q", "-m", "integration", "tests/test_trade_writer.py"],
                ),
                run_cmd(
                    "update matcher integration tests",
                    ["pytest", "-q", "-m", "integration", "tests/test_update_matcher.py"],
                ),
                run_cmd(
                    "update applier integration tests",
                    ["pytest", "-q", "-m", "integration", "tests/test_update_applier.py"],
                ),
                run_cmd(
                    "management rules integration tests",
                    ["pytest", "-q", "-m", "integration", "tests/test_management_rules.py"],
                ),
                run_cmd(
                    "edit handling integration tests",
                    ["pytest", "-q", "-m", "integration", "tests/test_edit_handling.py"],
                ),
            ]
        )

    if args.run_smoke:
        checks.append(
            run_cmd(
                "milestone 5 smoke flow",
                ["python", "scripts/smoke_milestone5_flow.py", "--auto-cleanup"],
            )
        )

    print("\nMilestone 5 — Acceptance Check")
    print("----------------------------------")
    for c in checks:
        print_result(c)

    failed = [c for c in checks if not c.ok]
    print("----------------------------------")
    if failed:
        print(f"❌ Milestone 5 NOT ACCEPTED ({len(failed)} failures)")
        return 1

    print("✅ Milestone 5 ACCEPTED")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
