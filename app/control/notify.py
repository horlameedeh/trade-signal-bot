from __future__ import annotations
from typing import Protocol

class TelegramClient(Protocol):
    async def send_message(self, chat_id: int, text: str) -> None: ...

async def send_control_alert(tg: TelegramClient, control_chat_id: int, text: str) -> None:
    await tg.send_message(control_chat_id, f"🚨 ROUTING ALERT\n{text}")
