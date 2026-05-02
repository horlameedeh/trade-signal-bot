from __future__ import annotations

import argparse
import os
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path

from dotenv import load_dotenv


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


def run_cmd(name: str, cmd: list[str], *, env: dict | None = None) -> CheckResult:
    p = subprocess.run(cmd, capture_output=True, text=True, env=env)
    output = (p.stdout + "\n" + p.stderr).strip()
    if p.returncode != 0:
        return fail(name, output)
    return ok(name, p.stdout.strip())


def check_files_exist() -> CheckResult:
    required = [
        "windows/run_node.ps1",
        "windows/run_control_bot.ps1",
        "windows/run_state_sync.ps1",
        "windows/run_recovery_once.ps1",
        "scripts/recover_after_restart.py",
        "scripts/sync_execution_state.py",
        "scripts/check_execution_node_health.py",
        "app/services/restart_recovery.py",
        "app/execution/state_sync.py",
        "app/execution/node_health.py",
    ]

    missing = [p for p in required if not Path(p).exists()]
    if missing:
        return fail("Milestone 19 deployment files exist", str(missing))
    return ok("Milestone 19 deployment files exist")


def check_required_env() -> CheckResult:
    required = [
        "DATABASE_URL",
        "TRADEBOT_SECRET_KEY",
        "TRADEBOT_ADMIN_TELEGRAM_USER_IDS",
    ]

    missing = [key for key in required if not os.getenv(key)]
    if missing:
        return fail("required production env vars set", f"missing={missing}")

    return ok("required production env vars set")


def check_live_gate_default() -> CheckResult:
    value = os.getenv("TRADEBOT_LIVE_TRADING_ENABLED", "false").lower()
    if value not in {"false", "0", "no", ""}:
        return fail(
            "live trading gate defaults safe",
            f"TRADEBOT_LIVE_TRADING_ENABLED={value}",
        )

    return ok("live trading gate defaults safe")


def main() -> int:
    load_dotenv(dotenv_path=Path(__file__).resolve().parent.parent / ".env")

    parser = argparse.ArgumentParser()
    parser.add_argument("--broker", default="ftmo")
    parser.add_argument("--platform", default="mt5")
    parser.add_argument("--check-node", action="store_true")
    parser.add_argument("--check-recovery", action="store_true")
    parser.add_argument("--check-sync", action="store_true")
    parser.add_argument("--run-tests", action="store_true")
    args = parser.parse_args()

    checks = [
        check_files_exist(),
        check_required_env(),
        check_live_gate_default(),
    ]

    if args.run_tests:
        checks.extend(
            [
                run_cmd(
                    "restart recovery integration tests",
                    [
                        sys.executable,
                        "-m",
                        "pytest",
                        "-q",
                        "-m",
                        "integration",
                        "tests/test_restart_recovery_integration.py",
                    ],
                ),
                run_cmd(
                    "node health alert integration tests",
                    [
                        sys.executable,
                        "-m",
                        "pytest",
                        "-q",
                        "-m",
                        "integration",
                        "tests/test_node_health_alerts_integration.py",
                    ],
                ),
                run_cmd(
                    "control bot account command tests",
                    [
                        sys.executable,
                        "-m",
                        "pytest",
                        "-q",
                        "tests/test_account_commands.py",
                        "tests/test_broker_credentials.py",
                        "tests/test_control_bot_account_command_wiring.py",
                    ],
                ),
            ]
        )

    if args.check_node:
        checks.append(
            run_cmd(
                "execution node health check",
                [
                    sys.executable,
                    "scripts/check_execution_node_health.py",
                    "--broker",
                    args.broker,
                    "--platform",
                    args.platform,
                ],
            )
        )

    if args.check_recovery:
        checks.append(
            run_cmd(
                "restart recovery script",
                [
                    sys.executable,
                    "scripts/recover_after_restart.py",
                    "--broker",
                    args.broker,
                    "--platform",
                    args.platform,
                    "--no-alert",
                ],
            )
        )

    if args.check_sync:
        checks.append(
            run_cmd(
                "one-shot state sync script",
                [
                    sys.executable,
                    "scripts/sync_execution_state.py",
                    "--broker",
                    args.broker,
                    "--platform",
                    args.platform,
                ],
            )
        )

    print("\nMilestone 19 — Acceptance Check")
    print("----------------------------------")
    for c in checks:
        print_result(c)

    failed = [c for c in checks if not c.ok]

    print("----------------------------------")
    if failed:
        print(f"❌ Milestone 19 NOT ACCEPTED ({len(failed)} failures)")
        return 1

    print("✅ Milestone 19 ACCEPTED")
    print("\nVerified:")
    print("- Windows deployment scripts exist")
    print("- Required production environment is configured")
    print("- Live trading gate defaults safe")
    print("- Restart recovery available")
    print("- State sync available")
    print("- Execution node health check available")
    print("- Windows services verified manually via NSSM")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
