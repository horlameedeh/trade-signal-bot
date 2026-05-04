from __future__ import annotations

import subprocess
import sys
from pathlib import Path

REQUIRED_FILES = [
    "app/execution/terminal_sessions.py",
    "app/execution/guarded_live_executor.py",
    "tests/test_guarded_terminal_routing_integration.py",
]


def check_files() -> None:
    missing = [f for f in REQUIRED_FILES if not Path(f).exists()]
    if missing:
        raise SystemExit(f"missing files: {missing}")
    print("✅ Milestone 27 Phase 3 files exist")


def check_wiring() -> None:
    src = Path("app/execution/guarded_live_executor.py").read_text()
    required = [
        "resolve_terminal_session_for_account",
        "TerminalSessionRoutingError",
        "terminal_routing_block",
        "_assert_terminal_session_routing",
    ]
    missing = [x for x in required if x not in src]
    if missing:
        raise SystemExit(f"missing guarded executor terminal-routing wiring: {missing}")
    print("✅ Terminal-session guard is wired into guarded execution")


def run_tests() -> None:
    cmd = [
        sys.executable,
        "-m",
        "pytest",
        "-q",
        "tests/test_terminal_session_routing.py",
        "tests/test_guarded_terminal_routing_integration.py",
        "tests/test_guarded_global_safety_integration.py",
        "tests/test_account_routing_guard.py",
    ]
    print("+", " ".join(cmd))
    subprocess.run(cmd, check=True)


def main() -> int:
    print("\nMilestone 27 Phase 3 — Execution Terminal Routing Acceptance")
    print("-----------------------------------------------------------")
    check_files()
    check_wiring()
    run_tests()
    print("-----------------------------------------------------------")
    print("✅ Milestone 27 Phase 3 ACCEPTED\n")
    print("Verified:")
    print("- Guarded execution checks terminal routing before adapter execution")
    print("- Missing terminal session blocks execution")
    print("- Ambiguous terminal session blocks execution")
    print("- Terminal routing blocks are logged to control_actions")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())