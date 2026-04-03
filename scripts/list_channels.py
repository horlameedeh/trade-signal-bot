"""
List Telegram dialogs/channels to confirm IDs.

Prints: title | username | numeric id | type

Usage:
  PYTHONPATH=. python scripts/list_channels.py --limit 200
  PYTHONPATH=. python scripts/list_channels.py --search "Fred"
"""
import argparse
import asyncio

from telethon.tl.types import Channel, Chat, User
from app.telegram.user_client import get_user_client, ensure_signed_in

def _etype(ent) -> str:
    if isinstance(ent, Channel):
        return "channel"
    if isinstance(ent, Chat):
        return "group"
    if isinstance(ent, User):
        return "user"
    return type(ent).__name__.lower()

def _fmt(s: str | None, n: int) -> str:
    s = s or ""
    return (s[: n - 1] + "…") if len(s) >= n else s

async def run(limit: int, search: str | None) -> None:
    client = get_user_client()
    await ensure_signed_in(client)

    rows = []
    async for dialog in client.iter_dialogs(limit=limit):
        ent = dialog.entity
        title = getattr(ent, "title", None) or dialog.name or ""
        username = getattr(ent, "username", None) or ""
        did = getattr(ent, "id", None)
        typ = _etype(ent)

        if search:
            hay = f"{title} {username} {did} {typ}".lower()
            if search.lower() not in hay:
                continue

        rows.append((title, username, did, typ))

    await client.disconnect()

    print(f"{'TITLE':52}  {'USERNAME':25}  {'ID':12}  {'TYPE':10}")
    print("-" * 105)
    for title, username, did, typ in rows:
        print(f"{_fmt(title,52):52}  {_fmt(username,25):25}  {str(did):12}  {typ:10}")

async def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--limit", type=int, default=200)
    p.add_argument("--search", type=str, default=None)
    args = p.parse_args()
    await run(limit=args.limit, search=args.search)

if __name__ == "__main__":
    asyncio.run(main())
