import asyncio

from app.ingest.telethon_client import ensure_signed_in, get_user_client


async def main() -> None:
    client = get_user_client()
    await ensure_signed_in(client)
    await client.disconnect()
    print("Telethon session created/updated.")


if __name__ == "__main__":
    asyncio.run(main())
