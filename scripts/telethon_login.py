"""
Telethon login & session handling.

Creates/updates a Telethon user session stored outside the repo:
  ~/Library/Application Support/tradebot/telethon/<TELETHON_SESSION_NAME>.session

Usage:
  PYTHONPATH=. python scripts/telethon_login.py
"""
import asyncio
from app.telegram.user_client import get_user_client, ensure_signed_in

async def main() -> None:
    client = get_user_client()
    await ensure_signed_in(client)
    await client.disconnect()
    print("✅ Telethon session created/updated.")

if __name__ == "__main__":
    asyncio.run(main())
