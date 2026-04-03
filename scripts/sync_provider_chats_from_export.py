"""
Sync TELEGRAM_PROVIDER_CHAT_IDS in .env from var/telegram_dialogs.json.

Filters dialogs by keyword match on title/username. Also writes:
  var/providers_chat_ids.txt

Usage:
  PYTHONPATH=. python scripts/sync_provider_chats_from_export.py --mode replace
  PYTHONPATH=. python scripts/sync_provider_chats_from_export.py --mode merge --keywords "fred,billio,mubeen,billionaire"
  PYTHONPATH=. python scripts/sync_provider_chats_from_export.py --dry-run

Assumptions:
- scripts/export_dialogs.py created var/telegram_dialogs.json
- JSON rows contain: title, username, id, neg100_id
"""
from __future__ import annotations

from pathlib import Path
import json
import re
from typing import Iterable, List, Set

ENV_PATH = Path(".env")
DIALOGS_JSON = Path("var/telegram_dialogs.json")
OUT_IDS = Path("var/providers_chat_ids.txt")


DEFAULT_KEYWORDS = ["fredtrading", "fred", "billio", "billionaire", "mubeen"]


def _parse_csv(v: str) -> List[str]:
    return [x.strip() for x in v.split(",") if x.strip()]


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
    if not txt.endswith("\n"):
        txt += "\n"
    return txt + line + "\n"


def _matches_keywords(title: str, username: str, keywords: List[str]) -> bool:
    hay = f"{title} {username}".lower()
    return any(k.lower() in hay for k in keywords)


def main() -> None:
    import argparse

    p = argparse.ArgumentParser()
    p.add_argument("--mode", choices=["merge", "replace"], default="replace")
    p.add_argument("--keywords", type=str, default=",".join(DEFAULT_KEYWORDS))
    p.add_argument("--dry-run", action="store_true")
    args = p.parse_args()

    if not DIALOGS_JSON.exists():
        raise SystemExit("❌ Missing var/telegram_dialogs.json. Run: PYTHONPATH=. python scripts/export_dialogs.py --limit 200")

    keywords = _parse_csv(args.keywords)

    dialogs = json.loads(DIALOGS_JSON.read_text(encoding="utf-8"))
    provider_ids: Set[int] = set()

    matched_rows = []
    for r in dialogs:
        title = (r.get("title") or "").strip()
        username = (r.get("username") or "").strip()
        neg100 = (r.get("neg100_id") or "").strip()

        if not neg100:
            continue
        if _matches_keywords(title, username, keywords):
            try:
                provider_ids.add(int(neg100))
                matched_rows.append((neg100, title, username))
            except ValueError:
                pass

    if not provider_ids:
        print("⚠️ No provider chats matched. Try broader --keywords.")
        return

    # Write repo output file
    OUT_IDS.parent.mkdir(parents=True, exist_ok=True)
    OUT_IDS.write_text("\n".join(str(x) for x in sorted(provider_ids)) + "\n", encoding="utf-8")

    print(f"✅ Wrote {OUT_IDS} ({len(provider_ids)} ids)")

    # Update .env
    if not ENV_PATH.exists():
        raise SystemExit("❌ .env not found in repo root")

    txt = ENV_PATH.read_text()

    existing = _parse_csv_ints(_get_env_value(txt, "TELEGRAM_PROVIDER_CHAT_IDS"))
    if args.mode == "merge":
        final = set().union(existing, provider_ids)
    else:
        final = provider_ids

    new_val = _format_csv_ints(final)

    if args.dry_run:
        print("🧪 Dry run (no .env change). Would set:")
        print("TELEGRAM_PROVIDER_CHAT_IDS=" + new_val)
    else:
        txt = _set_env_value(txt, "TELEGRAM_PROVIDER_CHAT_IDS", new_val)
        ENV_PATH.write_text(txt)
        print("✅ Updated .env TELEGRAM_PROVIDER_CHAT_IDS")

    # Print a small preview of matches
    print("\nMatched dialogs (first 20):")
    for neg100, title, username in matched_rows[:20]:
        u = f"@{username}" if username else ""
        print(f"  {neg100}  {title} {u}")


if __name__ == "__main__":
    main()
