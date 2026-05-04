from __future__ import annotations

import subprocess
import sys
from pathlib import Path

REQUIRED_FILES = [
    "app/execution/terminal_sessions.py",
    "tests/test_terminal_session_heartbeat.py",
    "tests/test_guarded_terminal_routing_integration.py",
]


def check_files() -> None:
    missing = [f for f in REQUIRED_FILES if not Path(f).exists()]
    if missing:
        raise SystemExit(f"missing files: {missing}")
    print("✅ Milestone 27 Phase 4 files exist")


def check_wiring() -> None:
    src = Path("app/execution/terminal_sessions.py").read_text()
    required = [
        "HEARTBEAT_STALE_AFTER_SECONDS",
        "_is_stale_heartbeat",
        "stale_terminal_session",
    ]
    missing = [x for x in required if x not in src]
    if missing:
        raise SystemExit(f"missing terminal heartbeat wiring: {missing}")
    print("✅ Terminal heartbeat stale-session guard exists")


def run_tests() -> None:
    cmd = [
        sys.executable,
        "-m",
        "pytest",
        "-q",
        "tests/test_terminal_sessions.py",
        "tests/test_terminal_session_routing.py",
        "tests/test_terminal_session_heartbeat.py",
        "tests/test_guarded_terminal_routing_integration.py",
    ]
    print("+", " ".join(cmd))
    subprocess.run(cmd, check=True)


def main() -> int:
    print("\nMilestone 27 Phase 4 — Terminal Heartbeat Acceptance")
    print("---------------------------------------------------")
    check_files()
    check_wiring()
    run_tests()
    print("---------------------------------------------------")
    print("✅ Milestone 27 Phase 4 ACCEPTED\n")
    print("Verified:")
    print("- Fresh terminal heartbeat allows routing")
    print("- Missing heartbeat blocks routing")
    print("- Stale heartbeat blocks routing")
    print("- Guarded execution blocks before adapter execution on stale terminal")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
