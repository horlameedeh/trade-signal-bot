from __future__ import annotations

import argparse
import os
import subprocess
from dataclasses import dataclass
from pathlib import Path

from sqlalchemy import text

from app.db.session import SessionLocal


REQUIRED_PROVIDERS = ["fredtrading", "billionaire_club", "mubeen"]

EXPECTED_CHAT_MAPPINGS = {
    "billionaire_club": [
        -1003254187278,
        -1002467468850,
        -1002997989063,
    ],
    "fredtrading": [
        -1001239815745,
        -1002208969496,
        -1001979286278,
    ],
    "mubeen": [
        -1002298510219,
        -1002808934766,
    ],
}


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


def check_tables_exist() -> CheckResult:
    needed = {"telegram_chats", "telegram_messages", "provider_account_routes", "routing_decisions"}
    with SessionLocal() as db:
        rows = db.execute(text("SELECT tablename FROM pg_tables WHERE schemaname='public'")).scalars().all()
    have = set(rows)
    missing = sorted(needed - have)
    if missing:
        return fail("DB tables exist", f"Missing: {missing}")
    return ok("DB tables exist")


def check_unique_chat_message() -> CheckResult:
    """
    Accept either:
      - a UNIQUE CONSTRAINT on (chat_id, message_id), OR
      - a UNIQUE INDEX on (chat_id, message_id)

    Both satisfy Postgres ON CONFLICT(chat_id, message_id).
    """
    with SessionLocal() as db:
        # 1) unique constraints
        cons = db.execute(
            text(
                """
                SELECT pg_get_constraintdef(oid) AS def
                FROM pg_constraint
                WHERE conrelid = 'public.routing_decisions'::regclass
                  AND contype = 'u';
                """
            )
        ).scalars().all()

        if any("UNIQUE (chat_id, message_id)" in (d or "") for d in cons):
            return ok("UNIQUE(chat_id,message_id) exists", "Found UNIQUE constraint")

        # 2) unique indexes
        idx = db.execute(
            text(
                """
                SELECT indexname, indexdef
                FROM pg_indexes
                WHERE schemaname='public' AND tablename='routing_decisions';
                """
            )
        ).mappings().all()

    # Look for "UNIQUE" and "(chat_id, message_id)" in index definition
    for r in idx:
        idef = r["indexdef"] or ""
        if "UNIQUE" in idef.upper() and "(chat_id, message_id)" in idef:
            return ok("UNIQUE(chat_id,message_id) exists", f"Found UNIQUE index: {r['indexname']}")

    return fail(
        "UNIQUE(chat_id,message_id) exists",
        "No UNIQUE constraint or UNIQUE index found for (chat_id, message_id).",
    )


def check_fk_telegram_msg_pk() -> CheckResult:
    with SessionLocal() as db:
        fks = db.execute(
            text(
                """
                SELECT pg_get_constraintdef(oid) AS def
                FROM pg_constraint
                WHERE conrelid = 'public.routing_decisions'::regclass
                  AND contype = 'f';
                """
            )
        ).scalars().all()

    if any("FOREIGN KEY (telegram_msg_pk) REFERENCES telegram_messages(msg_pk)" in (d or "") for d in fks):
        return ok("FK telegram_msg_pk exists")
    return fail("FK telegram_msg_pk exists", str(fks))


def check_provider_routes() -> CheckResult:
    with SessionLocal() as db:
        rows = db.execute(
            text(
                """
                SELECT provider_code, is_active
                FROM provider_account_routes
                WHERE provider_code = ANY(:providers);
                """
            ),
            {"providers": REQUIRED_PROVIDERS},
        ).mappings().all()

    found = {r["provider_code"]: bool(r["is_active"]) for r in rows}
    missing = [p for p in REQUIRED_PROVIDERS if p not in found]
    if missing:
        return fail("Provider routes exist", f"Missing routes: {missing}")

    inactive = [p for p, active in found.items() if not active]
    if inactive:
        return fail("Provider routes active", f"Inactive: {inactive}")

    return ok("Provider routes active")


def check_chat_mappings() -> CheckResult:
    problems: list[str] = []
    with SessionLocal() as db:
        for provider, chat_ids in EXPECTED_CHAT_MAPPINGS.items():
            rows = db.execute(
                text(
                    """
                    SELECT chat_id, provider_code
                    FROM telegram_chats
                    WHERE chat_id = ANY(:ids);
                    """
                ),
                {"ids": chat_ids},
            ).mappings().all()

            found = {int(r["chat_id"]): (r["provider_code"] or None) for r in rows}

            for cid in chat_ids:
                if cid not in found:
                    problems.append(f"{provider}: missing telegram_chats row for chat_id={cid}")
                    continue
                if (found[cid] or "").lower() != provider:
                    problems.append(f"{provider}: chat_id={cid} provider_code={found[cid]!r}")

    if problems:
        # include a remediation hint for the most common failure
        hint = (
            "Hint: fix with control bot:\n"
            "  !addchannel <provider> <chat_id>\n"
            "or SQL:\n"
            "  UPDATE telegram_chats SET provider_code='<provider>' WHERE chat_id=<chat_id>;"
        )
        return fail("Channel→Provider mappings correct", "; ".join(problems) + "\n" + hint)

    return ok("Channel→Provider mappings correct")


def check_control_bot_wiring() -> CheckResult:
    path = Path("app/telegram/control_bot.py")
    if not path.exists():
        return fail("control_bot.py exists", "Missing app/telegram/control_bot.py")

    s = path.read_text(encoding="utf-8")
    required = ["!showrouting", "!whoami", "TELEGRAM_ADMIN_USER_IDS", "handle_admin_command"]
    missing = [x for x in required if x not in s]
    if missing:
        return fail("Control bot wiring present", f"Missing: {missing}")
    return ok("Control bot wiring present")


def run_pytest() -> CheckResult:
    p = subprocess.run(["pytest", "-q", "-m", "integration"], capture_output=True, text=True)
    if p.returncode != 0:
        return fail("pytest integration", (p.stdout + "\n" + p.stderr).strip())
    return ok("pytest integration", p.stdout.strip())


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--run-tests", action="store_true")
    args = ap.parse_args()

    checks = [
        check_tables_exist(),
        check_unique_chat_message(),
        check_fk_telegram_msg_pk(),
        check_provider_routes(),
        check_chat_mappings(),
        check_control_bot_wiring(),
    ]

    if args.run_tests:
        checks.append(run_pytest())

    print("\nMilestone 2 — Acceptance Check")
    print("----------------------------------")
    for c in checks:
        print_result(c)

    failed = [c for c in checks if not c.ok]
    print("----------------------------------")
    if failed:
        print(f"❌ Milestone 2 NOT ACCEPTED ({len(failed)} failures)")
        return 1

    print("✅ Milestone 2 ACCEPTED")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
