from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Optional

from sqlalchemy import text
from sqlalchemy.orm import Session

from app.routing.constants import PROVIDER_ALLOWED_BROKER_NAME, PROVIDER_CODES


@dataclass(frozen=True)
class ProviderRouteView:
    provider_code: str
    chat_ids: list[int]
    broker_account_id: Optional[str]
    broker_name: Optional[str]
    is_active: bool


class RoutingRepository:
    def __init__(self, db: Session):
        self.db = db

    # ---- telegram chat ↔ provider mapping ----
    def get_provider_for_chat(self, chat_id: int) -> Optional[str]:
        row = (
            self.db.execute(
                text("SELECT provider_code FROM telegram_chats WHERE chat_id = :chat_id"),
                {"chat_id": chat_id},
            )
            .mappings()
            .first()
        )
        return str(row["provider_code"]) if row and row["provider_code"] is not None else None

    def set_chat_provider(self, chat_id: int, provider_code: str) -> None:
        if provider_code not in PROVIDER_CODES:
            raise ValueError(f"Unknown provider_code: {provider_code}")

        # Ensure chat exists; if not, create it (safe default)
        self.db.execute(
            text(
                """
            INSERT INTO telegram_chats (chat_id, provider_code, is_control_chat)
            VALUES (:chat_id, :provider_code, false)
            ON CONFLICT (chat_id) DO UPDATE
              SET provider_code = EXCLUDED.provider_code,
                  updated_at = now()
            """
            ),
            {"chat_id": chat_id, "provider_code": provider_code},
        )

    def remove_chat_provider(self, chat_id: int, provider_code: str) -> None:
        # Only remove if it matches (idempotent)
        self.db.execute(
            text(
                """
            UPDATE telegram_chats
            SET provider_code = NULL,
                updated_at = now()
            WHERE chat_id = :chat_id AND provider_code = :provider_code
            """
            ),
            {"chat_id": chat_id, "provider_code": provider_code},
        )

    def list_chat_ids_by_provider(self) -> dict[str, list[int]]:
        rows = (
            self.db.execute(
                text(
                    """
            SELECT provider_code, chat_id
            FROM telegram_chats
            WHERE provider_code IS NOT NULL
            ORDER BY provider_code, chat_id
            """
                )
            )
            .mappings()
            .all()
        )

        out: dict[str, list[int]] = {}
        for r in rows:
            out.setdefault(str(r["provider_code"]), []).append(int(r["chat_id"]))
        return out

    # ---- provider ↔ account route ----
    def get_active_account_for_provider(self, provider_code: str) -> Optional[dict[str, Any]]:
        row = (
            self.db.execute(
                text(
                    """
            SELECT par.provider_code, par.broker_account_id, par.is_active,
                   ba.broker AS broker_name
            FROM provider_account_routes par
            JOIN broker_accounts ba ON ba.account_id = par.broker_account_id
            WHERE par.provider_code = :provider_code AND par.is_active = true
            """
                ),
                {"provider_code": provider_code},
            )
            .mappings()
            .first()
        )
        return dict(row) if row else None

    def upsert_provider_account_route(self, provider_code: str, broker_account_id: str) -> None:
        """Back-compat helper: activate route for provider.

        Previously relied on UNIQUE(provider_code) and used ON CONFLICT(provider_code).
        With history support, we keep this API but implement it via activate_provider_route().
        """
        # Reuse validation logic from activate_provider_route path (provider + broker constraints)
        if provider_code not in PROVIDER_CODES:
            raise ValueError(f"Unknown provider_code: {provider_code}")

        broker = (
            self.db.execute(
                text(
                    "SELECT account_id, broker AS broker_name FROM broker_accounts WHERE account_id = :id"
                ),
                {"id": broker_account_id},
            )
            .mappings()
            .first()
        )
        if not broker:
            raise ValueError(f"broker_account_id not found: {broker_account_id}")

        allowed = PROVIDER_ALLOWED_BROKER_NAME[provider_code]
        if str(broker["broker_name"]) != allowed:
            raise ValueError(
                f"Constraint violation: {provider_code} must route only to broker_name={allowed} "
                f"(got {broker['broker_name']})"
            )

        # History-friendly activation
        self.activate_provider_route(provider_code=provider_code, broker_account_id=broker_account_id)

    # ---- audit ----
    def activate_provider_route(self, *, provider_code: str, broker_account_id: str) -> None:
        """Activate a provider→account route deterministically (history-friendly).

        Ensures:
        - (provider_code, broker_account_id) row exists (insert if missing)
        - all other routes for provider_code are set inactive
        - this target route is set active

        Requires DB indexes (Path 2):
        - UNIQUE(provider_code, broker_account_id)
        - UNIQUE(provider_code) WHERE is_active=true
        """
        # Ensure row exists
        self.db.execute(
            text(
                """
                INSERT INTO provider_account_routes (provider_code, broker_account_id, is_active)
                VALUES (:p, CAST(:a AS uuid), false)
                ON CONFLICT (provider_code, broker_account_id) DO NOTHING;
                """
            ),
            {"p": provider_code, "a": broker_account_id},
        )

        # Deactivate all routes for provider
        self.db.execute(
            text(
                """
                UPDATE provider_account_routes
                SET is_active=false, updated_at=now()
                WHERE provider_code = :p;
                """
            ),
            {"p": provider_code},
        )

        # Activate target route
        self.db.execute(
            text(
                """
                UPDATE provider_account_routes
                SET is_active=true, updated_at=now()
                WHERE provider_code = :p
                  AND broker_account_id = CAST(:a AS uuid);
                """
            ),
            {"p": provider_code, "a": broker_account_id},
        )

    def insert_routing_decision(
        self,
        *,
        telegram_message_id: int | None,
        chat_id: int,
        message_id: int | None,
        provider_code: str | None,
        broker_account_id: str | None,
        decision: str,
        reason: str | None,
        message_ts=None,
        raw_meta=None,
    ) -> None:
        from app.ingest.storage import _ensure_json

        self.db.execute(
            text(
                """
                INSERT INTO routing_decisions (
                  telegram_message_id,
                  chat_id,
                  message_id,
                  provider_code,
                  broker_account_id,
                  decision,
                  reason,
                  message_ts,
                  raw_meta
                )
                VALUES (
                  :telegram_message_id,
                  :chat_id,
                  :message_id,
                  :provider_code,
                  :broker_account_id,
                  :decision,
                  :reason,
                  :message_ts,
                  CAST(:raw_meta AS jsonb)
                )
                ON CONFLICT (chat_id, message_id) DO NOTHING;
                """
            ),
            {
                "telegram_message_id": telegram_message_id,
                "chat_id": chat_id,
                "message_id": message_id,
                "provider_code": provider_code,
                "broker_account_id": broker_account_id,
                "decision": decision,
                "reason": reason,
                "message_ts": message_ts,
                "raw_meta": _ensure_json(raw_meta or {}),
            },
        )

    def show_routing(self) -> list[ProviderRouteView]:
        chat_map = self.list_chat_ids_by_provider()

        routes = (
            self.db.execute(
                text(
                    """
            SELECT par.provider_code, par.broker_account_id, par.is_active, ba.broker AS broker_name
            FROM provider_account_routes par
            JOIN broker_accounts ba ON ba.account_id = par.broker_account_id
            ORDER BY par.provider_code
            """
                )
            )
            .mappings()
            .all()
        )

        out: list[ProviderRouteView] = []
        for r in routes:
            prov = str(r["provider_code"])
            out.append(
                ProviderRouteView(
                    provider_code=prov,
                    chat_ids=chat_map.get(prov, []),
                    broker_account_id=str(r["broker_account_id"]) if r["broker_account_id"] else None,
                    broker_name=str(r["broker_name"]) if r["broker_name"] else None,
                    is_active=bool(r["is_active"]),
                )
            )

        # include providers that have chats but no route row yet
        for prov, chat_ids in chat_map.items():
            if not any(x.provider_code == prov for x in out):
                out.append(
                    ProviderRouteView(
                        provider_code=prov,
                        chat_ids=chat_ids,
                        broker_account_id=None,
                        broker_name=None,
                        is_active=False,
                    )
                )
        return sorted(out, key=lambda x: x.provider_code)
