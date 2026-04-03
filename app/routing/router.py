from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Optional

from sqlalchemy.orm import Session

from app.control.notify import send_control_alert
from app.routing.repository import RoutingRepository


@dataclass(frozen=True)
class RouteDecision:
    chat_id: int
    provider_code: str
    broker_account_id: str


class Router:
    def __init__(self, db: Session, *, tg_client, control_chat_id: int):
        self.db = db
        self.repo = RoutingRepository(db)
        self.tg = tg_client
        self.control_chat_id = control_chat_id

    async def route_message(
        self,
        *,
        chat_id: int,
        telegram_message_id: int | None,
        raw_meta: dict[str, Any] | None = None,
        message_ts=None,
    ) -> Optional[RouteDecision]:
        provider = self.repo.get_provider_for_chat(chat_id)

        if not provider:
            self.repo.insert_routing_decision(
                telegram_message_id=telegram_message_id,
                chat_id=chat_id,
                message_id=telegram_message_id,
                provider_code=None,
                broker_account_id=None,
                decision="IGNORED_UNKNOWN_CHAT",
                reason="No chat_id → provider mapping",
                message_ts=message_ts,
                raw_meta=raw_meta,
            )
            self.db.commit()
            await send_control_alert(
                self.tg,
                self.control_chat_id,
                f"Unknown chat_id {chat_id}. Message ignored. Add mapping with: !addchannel <provider> {chat_id}",
            )
            return None

        route = self.repo.get_active_account_for_provider(provider)
        if not route:
            self.repo.insert_routing_decision(
                telegram_message_id=telegram_message_id,
                chat_id=chat_id,
                message_id=telegram_message_id,
                provider_code=provider,
                broker_account_id=None,
                decision="IGNORED_NO_ACCOUNT",
                reason="Provider has no active mapped account",
                message_ts=message_ts,
                raw_meta=raw_meta,
            )
            self.db.commit()
            await send_control_alert(
                self.tg,
                self.control_chat_id,
                f"Provider '{provider}' has no active mapped broker account. Message ignored.",
            )
            return None

        decision = RouteDecision(
            chat_id=chat_id,
            provider_code=provider,
            broker_account_id=str(route["broker_account_id"]),
        )

        self.repo.insert_routing_decision(
            telegram_message_id=telegram_message_id,
            chat_id=chat_id,
            message_id=telegram_message_id,
            provider_code=provider,
            broker_account_id=decision.broker_account_id,
            decision="ROUTED",
            reason=None,
            message_ts=message_ts,
            raw_meta=raw_meta,
        )
        self.db.commit()
        return decision
