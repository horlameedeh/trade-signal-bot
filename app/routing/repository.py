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
    route_priority: int = 100
    route_role: str = "primary"


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
    def list_active_accounts_for_provider(self, provider_code: str) -> list[dict[str, Any]]:
        rows = (
            self.db.execute(
                text(
                    """
            SELECT
              par.provider_code,
              par.broker_account_id,
              par.is_active,
              par.route_priority,
              par.route_role,
              ba.broker AS broker_name,
              ba.is_active AS broker_active
            FROM provider_account_routes par
            JOIN broker_accounts ba ON ba.account_id = par.broker_account_id
            WHERE par.provider_code = :provider_code
              AND par.is_active = true
            ORDER BY par.route_priority ASC, par.updated_at DESC NULLS LAST, par.id ASC
            """
                ),
                {"provider_code": provider_code},
            )
            .mappings()
            .all()
        )
        return [dict(row) for row in rows]

    def get_active_account_for_provider(self, provider_code: str) -> Optional[dict[str, Any]]:
        """Return the first active route by priority.

        Back-compat API for callers that still expect one selected account.
        Fallback-aware callers should use list_active_accounts_for_provider().
        """
        routes = self.list_active_accounts_for_provider(provider_code)
        return routes[0] if routes else None

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

        # Back-compat activation keeps old behavior: one active route for provider.
        self.activate_provider_route(provider_code=provider_code, broker_account_id=broker_account_id)

    # ---- audit ----
    def activate_provider_route(self, *, provider_code: str, broker_account_id: str) -> None:
        """Back-compat single-route activation.

        This preserves the old command behavior by deactivating other routes for
        the provider, then activating the target as priority 100 / primary.

        New fallback-aware code should call upsert_provider_fallback_route().
        """
        self.upsert_provider_fallback_route(
            provider_code=provider_code,
            broker_account_id=broker_account_id,
            route_priority=100,
            route_role="primary",
            deactivate_other_routes=True,
        )

    def upsert_provider_fallback_route(
        self,
        *,
        provider_code: str,
        broker_account_id: str,
        route_priority: int,
        route_role: str,
        is_active: bool = True,
        deactivate_other_routes: bool = False,
    ) -> None:
        """Create/update one provider route without requiring single-active routing.

        Multiple active routes per provider are allowed when they have distinct
        route_priority values. Lower priority values are preferred first.
        """
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

        if deactivate_other_routes:
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

        self.db.execute(
            text(
                """
                INSERT INTO provider_account_routes (
                  provider_code,
                  broker_account_id,
                  is_active,
                  route_priority,
                  route_role
                )
                VALUES (
                  :p,
                  CAST(:a AS uuid),
                  :active,
                  :priority,
                  :role
                )
                ON CONFLICT (provider_code, broker_account_id) DO UPDATE
                  SET is_active = EXCLUDED.is_active,
                      route_priority = EXCLUDED.route_priority,
                      route_role = EXCLUDED.route_role,
                      updated_at = now();
                """
            ),
            {
                "p": provider_code,
                "a": broker_account_id,
                "active": is_active,
                "priority": route_priority,
                "role": route_role,
            },
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
            SELECT
              par.provider_code,
              par.broker_account_id,
              par.is_active,
              par.route_priority,
              par.route_role,
              ba.broker AS broker_name
            FROM provider_account_routes par
            JOIN broker_accounts ba ON ba.account_id = par.broker_account_id
            ORDER BY par.provider_code, par.route_priority, ba.broker
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
                    route_priority=int(r["route_priority"]),
                    route_role=str(r["route_role"]),
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
