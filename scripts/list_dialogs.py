"""
List dialogs to confirm channel/group IDs.

Usage:
  PYTHONPATH=. python scripts/list_dialogs.py --limit 200
  PYTHONPATH=. python scripts/list_dialogs.py --search "Fred"
"""
import argparse
import asyncio

from app.ingest.telethon_client import get_user_client, ensure_signed_in

def _fmt(s: str | None, n: int) -> str:
    s = s or ""
    return (s[: n - 1] + "…") if len(s) >= n else s

async def run(limit: int, search: str | None) -> None:
    client = get_user_client()
    await ensure_signed_in(client)

    rows = []
    async for dialog in client.iter_dialogs(limit=limit):
        ent = dialog.entity
        title = getattr(ent, "title", None) or dialog.name
        username = getattr(ent, "username", None)
        did = getattr(ent, "id", None)

        # Telethon entity.id is positive; event.chat_id commonly uses -100 prefix for channels/supergroups.
        # For your allowlist, you typically want the -100... form you see in your DB.
        # We'll print both to be explicit.
        neg100 = f"-100{did}" if did and str(did).isdigit() else ""

        if search:
            hay = f"{title or ''} {username or ''} {did or ''} {neg100}"
            if search.lower() not in hay.lower():
                continue

        rows.append((title, username or "", did or "", neg100))

    await client.disconnect()

    print(f"{'TITLE':50}  {'USERNAME':25}  {'ID':12}  {'-100ID':16}")
    print("-" * 115)
    for title, username, did, neg100 in rows:
        print(f"{_fmt(title,50):50}  {_fmt(username,25):25}  {str(did):12}  {str(neg100):16}")

async def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--limit", type=int, default=200)
    p.add_argument("--search", type=str, default=None)
    args = p.parse_args()
    await run(limit=args.limit, search=args.search)

if __name__ == "__main__":
    asyncio.run(main())
