from __future__ import annotations


def normalize_chat_id(chat_id: int) -> int:
    """Canonicalize Telegram channel/supergroup IDs.

    Telethon commonly yields channel/supergroup chat_id as -100xxxxxxxxxx.
    Some contexts/tools may yield the positive export id (xxxxxxxxxx).

    We store and route using the canonical negative form.
    """

    # If it already looks like a channel/supergroup id, keep it
    if chat_id <= -1000000000000:
        return chat_id

    # If it's a normal negative (some basic groups), keep as-is
    if chat_id < 0:
        return chat_id

    # Convert positive export id -> -100... form
    return int(f"-100{chat_id}")
