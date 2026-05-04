from __future__ import annotations

import subprocess
import sys
from pathlib import Path

REQUIRED_FILES = [
    "app/execution/terminal_heartbeat.py",
    "scripts/terminal_heartbeat.py",
    "windows/manage_terminal_heartbeat.ps1",
    "tests/test_terminal_heartbeat_writer.py",
]


def check_files() -> None:
    missing = [f for f in REQUIRED_FILES if not Path(f).exists()]
    if missing:
        raise SystemExit(f"missing files: {missing}")
    print("✅ Milestone 27 Phase 5 files exist")


def check_wiring() -> None:
    src = Path("app/execution/terminal_heartbeat.py").read_text()
    required = [
        "touch_terminal_session",
        "mark_terminal_session_stopped",
        "last_heartbeat = now()",
    ]
    missing = [x for x in required if x not in src]
    if missing:
        raise SystemExit(f"missing heartbeat writer wiring: {missing}")
    print("✅ Terminal heartbeat writer exists")


def run_tests() -> None:
    cmd = [
        sys.executable,
        "-m",
        "pytest",
        "-q",
        "tests/test_terminal_heartbeat_writer.py",
        "tests/test_terminal_session_heartbeat.py",
        "tests/test_terminal_session_routing.py",
        "tests/test_guarded_terminal_routing_integration.py",
    ]
    print("+", " ".join(cmd))
    subprocess.run(cmd, check=True)


def main() -> int:
    print("\nMilestone 27 Phase 5 — Terminal Heartbeat Writer Acceptance")
    print("----------------------------------------------------------")
    check_files()
    check_wiring()
    run_tests()
    print("----------------------------------------------------------")
    print("✅ Milestone 27 Phase 5 ACCEPTED\n")
    print("Verified:")
    print("- Known terminal sessions can update last_heartbeat")
    print("- Unknown terminal sessions are refused")
    print("- Terminal sessions can be marked stopped")
    print("- Stale-session routing protection remains active")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
