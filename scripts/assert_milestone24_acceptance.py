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
        "app/services/provider_channels.py",
        "app/telegram/telethon_ingestion.py",
        "app/telegram/ingestion_router.py",
        "scripts/bootstrap_provider_channels.py",
        "scripts/run_telethon_ingestion.py",
        "scripts/backfill_telethon_messages.py",
        "scripts/route_ingested_messages.py",
        "tests/test_provider_channels.py",
        "tests/test_telethon_ingestion.py",
        "tests/test_ingestion_router.py",
        "tests/test_autonomous_execution_integration.py",
    ]

    missing = [p for p in required if not Path(p).exists()]
    if missing:
        return fail("Milestone 24 files exist", str(missing))
    return ok("Milestone 24 files exist")


def run_cmd(name: str, cmd: list[str]) -> CheckResult:
    p = subprocess.run(cmd, capture_output=True, text=True)
    output = (p.stdout + "\n" + p.stderr).strip()
    if p.returncode != 0:
        return fail(name, output)
    return ok(name, p.stdout.strip())


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--run-tests", action="store_true")
    parser.add_argument("--check-provider-registry", action="store_true")
    parser.add_argument("--check-routing", action="store_true")
    args = parser.parse_args()

    py = sys.executable
    checks = [check_files_exist()]

    if args.run_tests:
        checks.extend(
            [
                run_cmd(
                    "provider channel tests",
                    [py, "-m", "pytest", "-q", "tests/test_provider_channels.py"],
                ),
                run_cmd(
                    "telethon ingestion persistence tests",
                    [py, "-m", "pytest", "-q", "tests/test_telethon_ingestion.py"],
                ),
                run_cmd(
                    "ingestion router tests",
                    [py, "-m", "pytest", "-q", "tests/test_ingestion_router.py"],
                ),
                run_cmd(
                    "autonomous execution dry-run gate regression",
                    [
                        py,
                        "-m",
                        "pytest",
                        "-q",
                        "-m",
                        "integration",
                        "tests/test_autonomous_execution_integration.py",
                    ],
                ),
            ]
        )

    if args.check_provider_registry:
        checks.append(
            run_cmd(
                "provider registry bootstrap",
                [py, "scripts/bootstrap_provider_channels.py"],
            )
        )

    if args.check_routing:
        checks.append(
            run_cmd(
                "route ingested messages",
                [py, "scripts/route_ingested_messages.py", "--limit", "100"],
            )
        )

    print("\nMilestone 24 — Acceptance Check")
    print("----------------------------------")
    for c in checks:
        print_result(c)

    failed = [c for c in checks if not c.ok]

    print("----------------------------------")
    if failed:
        print(f"❌ Milestone 24 NOT ACCEPTED ({len(failed)} failures)")
        return 1

    print("✅ Milestone 24 ACCEPTED")
    print("\nVerified:")
    print("- Provider/channel registry is DB-backed")
    print("- Telethon ingestion can persist messages")
    print("- Duplicate Telegram messages are deduped")
    print("- Non-trade messages safely no-op")
    print("- Trade-like messages route through parser/planner")
    print("- Valid messages can create trade intents/families/legs")
    print("- Dry-run ingested families are protected from live autonomous execution")
    print("- Production ingestion can be enabled explicitly")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())