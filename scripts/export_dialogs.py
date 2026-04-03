"""
Export Telethon dialogs to repo files.

Outputs:
  var/telegram_dialogs.tsv
  var/telegram_dialogs.json

Usage:
  PYTHONPATH=. python scripts/export_dialogs.py --limit 200
  PYTHONPATH=. python scripts/export_dialogs.py --limit 200 --search "Fred"
"""
from __future__ import annotations

import argparse
import asyncio
import json
from pathlib import Path
from typing import Any, Dict, List, Optional

from app.ingest.telethon_client import get_user_client, ensure_signed_in


def _neg100_id(entity_id: Optional[int]) -> Optional[str]:
    if not entity_id:
        return None
    return f"-100{entity_id}"


async def run(limit: int, search: Optional[str]) -> None:
    out_tsv = Path("var/telegram_dialogs.tsv")
    out_json = Path("var/telegram_dialogs.json")
    out_tsv.parent.mkdir(parents=True, exist_ok=True)

    client = get_user_client()
    await ensure_signed_in(client)

    rows: List[Dict[str, Any]] = []

    async for dialog in client.iter_dialogs(limit=limit):
        ent = dialog.entity
        title = getattr(ent, "title", None) or dialog.name or ""
        username = getattr(ent, "username", None) or ""
        ent_id = getattr(ent, "id", None)

        neg100 = _neg100_id(ent_id) or ""

        if search:
            hay = f"{title} {username} {ent_id or ''} {neg100}"
            if search.lower() not in hay.lower():
                continue

        rows.append(
            {
                "title": title,
                "username": username,
                "id": ent_id,
                "neg100_id": neg100,
            }
        )

    await client.disconnect()

    # Write TSV
    with out_tsv.open("w", encoding="utf-8") as f:
        f.write("TITLE\tUSERNAME\tID\t-100ID\n")
        for r in rows:
            f.write(f"{r['title']}\t{r['username']}\t{r['id']}\t{r['neg100_id']}\n")

    # Write JSON
    out_json.write_text(json.dumps(rows, indent=2, ensure_ascii=False), encoding="utf-8")

    print(f"✅ Wrote {out_tsv}")
    print(f"✅ Wrote {out_json}")
    print(f"   Rows: {len(rows)}")


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--limit", type=int, default=200)
    p.add_argument("--search", type=str, default=None)
    args = p.parse_args()
    asyncio.run(run(limit=args.limit, search=args.search))


if __name__ == "__main__":
    main()
