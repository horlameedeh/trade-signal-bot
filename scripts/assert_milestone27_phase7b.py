from __future__ import annotations

import subprocess
import sys
from pathlib import Path

REQUIRED_FILES = [
    "app/execution/terminal_sessions.py",
    "app/execution/guarded_live_executor.py",
    "tests/test_terminal_session_routing.py",
    "tests/test_guarded_terminal_routing_integration.py",
    "tests/test_guarded_live_executor_terminal_routing.py",
]

REQUIRED_MARKERS = [
    "missing_account_owner",
    "missing_terminal_owner",
    "terminal_session_user_mismatch",
]

TESTS = [
    "tests/test_terminal_sessions.py",
    "tests/test_terminal_session_routing.py",
    "tests/test_guarded_terminal_routing_integration.py",
    "tests/test_guarded_live_executor_terminal_routing.py",
]


def check_files() -> None:
    for path in REQUIRED_FILES:
        if not Path(path).exists():
            raise SystemExit(f"missing required file: {path}")

    src = Path("app/execution/terminal_sessions.py").read_text(encoding="utf-8")
    for marker in REQUIRED_MARKERS:
        if marker not in src:
            raise SystemExit(f"missing routing marker in terminal_sessions.py: {marker}")

    print("✅ Phase 7B files and markers exist")


def run_tests() -> None:
    cmd = [sys.executable, "-m", "pytest", "-q", *TESTS]
    print("+ " + " ".join(cmd))
    subprocess.run(cmd, check=True)


def main() -> int:
    print("Milestone 27 Phase 7B — Owner-Aware Terminal Routing Acceptance")
    print("----------------------------------------------------------------")

    check_files()
    run_tests()

    print("----------------------------------------------------------------")
    print("✅ Milestone 27 Phase 7B ACCEPTED")
    print()
    print("Verified:")
    print("- Missing account owner blocks routing")
    print("- Missing terminal owner blocks routing")
    print("- Terminal/account owner mismatch blocks routing")
    print("- Owner-aware routing failures are logged to control_actions")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())