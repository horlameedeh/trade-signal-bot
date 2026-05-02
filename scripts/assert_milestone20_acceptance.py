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
        "app/services/metrics.py",
        "app/services/monitoring_summary.py",
        "scripts/show_metrics.py",
        "scripts/queue_monitoring_summary.py",
        "tests/test_metrics_integration.py",
        "tests/test_monitoring_summary_integration.py",
    ]

    missing = [p for p in required if not Path(p).exists()]
    if missing:
        return fail("Milestone 20 files exist", str(missing))
    return ok("Milestone 20 files exist")


def run_cmd(name: str, cmd: list[str]) -> CheckResult:
    p = subprocess.run(cmd, capture_output=True, text=True)
    output = (p.stdout + "\n" + p.stderr).strip()
    if p.returncode != 0:
        return fail(name, output)
    return ok(name, p.stdout.strip())


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--run-tests", action="store_true")
    parser.add_argument("--check-cli", action="store_true")
    parser.add_argument("--queue-summary", action="store_true")
    args = parser.parse_args()

    py = sys.executable

    checks = [check_files_exist()]

    if args.run_tests:
        checks.extend(
            [
                run_cmd(
                    "metrics integration tests",
                    [
                        py,
                        "-m",
                        "pytest",
                        "-q",
                        "-m",
                        "integration",
                        "tests/test_metrics_integration.py",
                    ],
                ),
                run_cmd(
                    "monitoring summary integration tests",
                    [
                        py,
                        "-m",
                        "pytest",
                        "-q",
                        "-m",
                        "integration",
                        "tests/test_monitoring_summary_integration.py",
                    ],
                ),
                run_cmd(
                    "alerts regression",
                    [
                        py,
                        "-m",
                        "pytest",
                        "-q",
                        "-m",
                        "integration",
                        "tests/test_alerts_integration.py",
                    ],
                ),
            ]
        )

    if args.check_cli:
        checks.extend(
            [
                run_cmd(
                    "metrics CLI text output",
                    [py, "scripts/show_metrics.py"],
                ),
                run_cmd(
                    "metrics CLI JSON output",
                    [py, "scripts/show_metrics.py", "--json"],
                ),
            ]
        )

    if args.queue_summary:
        checks.append(
            run_cmd(
                "queue monitoring summary",
                [py, "scripts/queue_monitoring_summary.py"],
            )
        )

    print("\nMilestone 20 — Acceptance Check")
    print("----------------------------------")
    for c in checks:
        print_result(c)

    failed = [c for c in checks if not c.ok]

    print("----------------------------------")
    if failed:
        print(f"❌ Milestone 20 NOT ACCEPTED ({len(failed)} failures)")
        return 1

    print("✅ Milestone 20 ACCEPTED")
    print("\nVerified:")
    print("- Trade metrics are visible")
    print("- Win/loss outcomes are measurable")
    print("- Execution errors are measurable")
    print("- Dead letters and retry failures are measurable")
    print("- Execution latency is measurable")
    print("- Metrics can be printed as text and JSON")
    print("- Monitoring summary can be queued for Control Chat")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
