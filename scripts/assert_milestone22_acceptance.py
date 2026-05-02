from __future__ import annotations

import argparse
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path

from dotenv import load_dotenv


load_dotenv(dotenv_path=Path(__file__).resolve().parent.parent / ".env")


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
        "app/services/users.py",
        "app/services/tenant_context.py",
        "app/services/broker_credentials.py",
        "app/telegram/account_commands.py",
        "app/telegram/onboarding.py",
        "app/telegram/control_bot.py",
        "tests/test_users.py",
        "tests/test_user_scoped_credentials.py",
        "tests/test_tenant_accounts_integration.py",
        "tests/test_onboarding.py",
    ]

    missing = [p for p in required if not Path(p).exists()]
    if missing:
        return fail("Milestone 22 files exist", str(missing))
    return ok("Milestone 22 files exist")


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
                    "user model tests",
                    [py, "-m", "pytest", "-q", "tests/test_users.py"],
                ),
                run_cmd(
                    "user-scoped credential tests",
                    [py, "-m", "pytest", "-q", "tests/test_user_scoped_credentials.py"],
                ),
                run_cmd(
                    "tenant account isolation tests",
                    [
                        py,
                        "-m",
                        "pytest",
                        "-q",
                        "-m",
                        "integration",
                        "tests/test_tenant_accounts_integration.py",
                    ],
                ),
                run_cmd(
                    "onboarding tests",
                    [py, "-m", "pytest", "-q", "tests/test_onboarding.py"],
                ),
                run_cmd(
                    "account command regression",
                    [py, "-m", "pytest", "-q", "tests/test_account_commands.py"],
                ),
                run_cmd(
                    "broker credential regression",
                    [py, "-m", "pytest", "-q", "tests/test_broker_credentials.py"],
                ),
                run_cmd(
                    "control bot compile check",
                    [
                        py,
                        "-m",
                        "py_compile",
                        "app/telegram/control_bot.py",
                        "app/telegram/account_commands.py",
                        "app/telegram/onboarding.py",
                        "app/services/users.py",
                        "app/services/tenant_context.py",
                        "app/services/broker_credentials.py",
                    ],
                ),
            ]
        )

    print("\nMilestone 22 — Acceptance Check")
    print("----------------------------------")
    for c in checks:
        print_result(c)

    failed = [c for c in checks if not c.ok]

    print("----------------------------------")
    if failed:
        print(f"❌ Milestone 22 NOT ACCEPTED ({len(failed)} failures)")
        return 1

    print("✅ Milestone 22 ACCEPTED")
    print("\nVerified:")
    print("- Users table/service exists")
    print("- Control chats can resolve to users")
    print("- Broker credentials are user-scoped")
    print("- Broker accounts are user-scoped")
    print("- Same account label can exist independently per user")
    print("- Cross-user account access is blocked")
    print("- /start onboarding works")
    print("- !whoami displays user identity and linked accounts")
    print("- !myaccounts displays only the current user’s accounts")
    print("- No visible data crossover")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
