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
        "config/symbol_maps.yaml",
        "app/services/symbol_aliases.py",
        "app/services/trade_writer.py",
        "tests/test_symbol_aliases.py",
        "tests/test_trade_writer_symbol_resolution_integration.py",
    ]
    missing = [p for p in required if not Path(p).exists()]
    if missing:
        return fail("Milestone 7 files exist", str(missing))
    return ok("Milestone 7 files exist")


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
                    "symbol alias unit tests",
                    ["pytest", "-q", "tests/test_symbol_aliases.py"],
                ),
                run_cmd(
                    "trade writer symbol resolution integration tests",
                    ["pytest", "-q", "-m", "integration", "tests/test_trade_writer_symbol_resolution_integration.py"],
                ),
                run_cmd(
                    "trade writer lot sizing regression",
                    ["pytest", "-q", "-m", "integration", "tests/test_trade_writer_lot_sizing_integration.py"],
                ),
            ]
        )

    print("\nMilestone 7 — Acceptance Check")
    print("----------------------------------")
    for c in checks:
        print_result(c)

    failed = [c for c in checks if not c.ok]
    print("----------------------------------")
    if failed:
        print(f"❌ Milestone 7 NOT ACCEPTED ({len(failed)} failures)")
        return 1

    print("✅ Milestone 7 ACCEPTED")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
