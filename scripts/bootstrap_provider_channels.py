from __future__ import annotations

import sys

from dotenv import load_dotenv

from app.services.provider_channels import list_enabled_provider_channels, upsert_provider_channel


PRODUCTION_CHANNELS = [
    ("billionaire_club", -1003254187278, "BILLIONAIRE CLUB 🔒", ""),
    ("fredtrading", -1001239815745, "Fredtrading - VIP - Main channel", ""),
    ("billionaire_club", -1002467468850, "BILLIO PREMIUM+ 🔐", ""),
    ("fredtrading", -1002208969496, "Fredtrading - VIP - Crypto community", ""),
    ("billionaire_club", -1002997989063, "BILLIO FUNDED VIP 🏦", ""),
    ("fredtrading", -1001979286278, "Fredtrading - Live trading / indices", ""),
    ("mubeen", -1002298510219, "Mubeen Trading", "mubeentrading"),
    ("mubeen", -1002808934766, "Mubeen Trading VIP", ""),
]


def _safe_print(message: str) -> None:
    encoding = sys.stdout.encoding or "utf-8"
    if hasattr(sys.stdout, "buffer"):
        sys.stdout.buffer.write((message + "\n").encode(encoding, errors="backslashreplace"))
        return

    print(message.encode(encoding, errors="backslashreplace").decode(encoding))


def main() -> int:
    load_dotenv()

    for provider_code, chat_id, title, username in PRODUCTION_CHANNELS:
        upsert_provider_channel(
            provider_code=provider_code,
            chat_id=chat_id,
            title=title,
            username=username or None,
            channel_type="signal",
            is_enabled=True,
            ingestion_mode="telethon",
        )
        _safe_print(f"upserted {provider_code} {chat_id} {title}")

    _safe_print("\nEnabled channels:")
    for ch in list_enabled_provider_channels():
        _safe_print(f"- {ch.provider_code}: {ch.chat_id} {ch.title}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
