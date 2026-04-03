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
        "app/parsing/models.py",
        "app/parsing/normalize.py",
        "app/parsing/symbols.py",
        "app/parsing/confidence.py",
        "app/parsing/parser.py",
        "app/parsing/persist.py",
        "app/parsing/service.py",
        "tests/test_parser_v1.py",
        "tests/test_parser_fixtures.py",
        "tests/test_persist_parser_integration.py",
        "tests/test_parsing_service_integration.py",
        "tests/fixtures/fredtrading_samples.txt",
        "tests/fixtures/billionaire_club_samples.txt",
        "tests/fixtures/mubeen_samples.txt",
    ]
    missing = [p for p in required if not Path(p).exists()]
    if missing:
        return fail("Milestone 3 files exist", str(missing))
    return ok("Milestone 3 files exist")


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
                run_cmd("parser unit tests", ["pytest", "-q", "tests/test_parser_v1.py", "tests/test_parser_fixtures.py"]),
                run_cmd(
                    "parser integration tests",
                    ["pytest", "-q", "-m", "integration", "tests/test_persist_parser_integration.py", "tests/test_parsing_service_integration.py"],
                ),
            ]
        )

    print("\nMilestone 3 — Acceptance Check")
    print("----------------------------------")
    for c in checks:
        print_result(c)

    failed = [c for c in checks if not c.ok]
    print("----------------------------------")
    if failed:
        print(f"❌ Milestone 3 NOT ACCEPTED ({len(failed)} failures)")
        return 1

    print("✅ Milestone 3 ACCEPTED")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
