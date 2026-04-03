"""
Seed/refresh TELEGRAM_*_CHAT_IDS in .env from the database (telegram_chats).

Writes/updates:
  TELEGRAM_CONTROL_CHAT_IDS
  TELEGRAM_PROVIDER_CHAT_IDS

Options:
  --providers "id1,id2,..."   -> merge/override provider ids (recommended if you already know them)
  --controls "id1,id2,..."    -> merge/override control ids
  --mode merge|replace        -> merge keeps existing .env values too; replace overwrites

Usage:
  PYTHONPATH=. python scripts/seed_allowlist_from_db.py --mode replace \
    --providers "-100..., -100..." \
    --controls "-5211338635"
"""
from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
import os
import re
from typing import Iterable, List, Set

from sqlalchemy import text
from app.db.session import SessionLocal


ENV_PATH = Path(".env")


def _parse_csv_ints(v: str | None) -> Set[int]:
    if not v:
        return set()
    out: Set[int] = set()
    for part in v.split(","):
        s = part.strip()
        if not s:
            continue
        out.add(int(s))
    return out


def _format_csv_ints(vals: Iterable[int]) -> str:
    return ", ".join(str(x) for x in sorted(set(vals)))


def _get_env_value(txt: str, key: str) -> str | None:
    m = re.search(rf"^{re.escape(key)}=(.*)$", txt, flags=re.MULTILINE)
    return m.group(1).strip() if m else None


def _set_env_value(txt: str, key: str, value: str) -> str:
    pattern = rf"^{re.escape(key)}=.*$"
    line = f"{key}={value}"
    if re.search(pattern, txt, flags=re.MULTILINE):
        return re.sub(pattern, line, txt, flags=re.MULTILINE)
    # append
    if not txt.endswith("\n"):
        txt += "\n"
    return txt + line + "\n"


def fetch_chat_ids_from_db() -> tuple[Set[int], Set[int]]:
    """
    Returns: (control_chat_ids, provider_chat_ids)
    Providers here are simply 'not control' chats in telegram_chats.
    """
    with SessionLocal() as db:
        rows = db.execute(
            text("select chat_id, is_control_chat from telegram_chats")
        ).fetchall()

    control: Set[int] = set()
    provider: Set[int] = set()
    for chat_id, is_control in rows:
        if is_control:
            control.add(int(chat_id))
        else:
            provider.add(int(chat_id))
    return control, provider


def main() -> None:
    import argparse

    p = argparse.ArgumentParser()
    p.add_argument("--mode", choices=["merge", "replace"], default="merge")
    p.add_argument("--providers", type=str, default=None, help="Comma-separated provider chat IDs to merge/replace")
    p.add_argument("--controls", type=str, default=None, help="Comma-separated control chat IDs to merge/replace")
    args = p.parse_args()

    if not ENV_PATH.exists():
        raise SystemExit("❌ .env not found in repo root")

    txt = ENV_PATH.read_text()

    db_controls, db_providers = fetch_chat_ids_from_db()

    # Existing .env values (only used in merge mode)
    existing_controls = _parse_csv_ints(_get_env_value(txt, "TELEGRAM_CONTROL_CHAT_IDS"))
    existing_providers = _parse_csv_ints(_get_env_value(txt, "TELEGRAM_PROVIDER_CHAT_IDS"))

    extra_controls = _parse_csv_ints(args.controls)
    extra_providers = _parse_csv_ints(args.providers)

    if args.mode == "replace":
        final_controls = (extra_controls or db_controls)
        final_providers = (extra_providers or db_providers)
    else:
        final_controls = set().union(existing_controls, db_controls, extra_controls)
        final_providers = set().union(existing_providers, db_providers, extra_providers)

    txt = _set_env_value(txt, "TELEGRAM_CONTROL_CHAT_IDS", _format_csv_ints(final_controls))
    txt = _set_env_value(txt, "TELEGRAM_PROVIDER_CHAT_IDS", _format_csv_ints(final_providers))

    ENV_PATH.write_text(txt)

    print("✅ Updated .env")
    print("   TELEGRAM_CONTROL_CHAT_IDS =", _format_csv_ints(final_controls))
    print("   TELEGRAM_PROVIDER_CHAT_IDS =", _format_csv_ints(final_providers))


if __name__ == "__main__":
    main()
