from __future__ import annotations

from sqlalchemy import text

from app.db.session import SessionLocal


def build_showrouting_text() -> str:
    """Build a readable routing summary (HTML).

    provider -> chats -> active target account
    """

    with SessionLocal() as db:
        # chat mappings
        chat_rows = (
            db.execute(
                text(
                    """
                SELECT provider_code, chat_id, title
                FROM telegram_chats
                WHERE provider_code IS NOT NULL
                ORDER BY provider_code, chat_id
            """
                )
            )
            .mappings()
            .all()
        )

        chats_by_provider: dict[str, list[str]] = {}
        for r in chat_rows:
            prov = r["provider_code"]
            label = f"{r['chat_id']}"
            if r.get("title"):
                label += f" — {r['title']}"
            chats_by_provider.setdefault(prov, []).append(label)

        # provider->account route
        route_rows = (
            db.execute(
                text(
                    """
                SELECT
                  par.provider_code,
                  par.is_active,
                  ba.account_id::text AS account_id,
                  ba.broker::text AS broker,
                  ba.platform::text AS platform,
                  ba.kind::text AS kind,
                  ba.label AS label
                FROM provider_account_routes par
                JOIN broker_accounts ba ON ba.account_id = par.broker_account_id
                ORDER BY par.provider_code
            """
                )
            )
            .mappings()
            .all()
        )

        route_by_provider: dict[str, dict] = {r["provider_code"]: dict(r) for r in route_rows}

        providers = sorted(set(chats_by_provider.keys()) | set(route_by_provider.keys()))
        if not providers:
            return "No routing configured yet."

        lines: list[str] = ["📌 <b>Current routing</b>"]
        for prov in providers:
            lines.append(f"\n<b>{prov}</b>")

            chats = chats_by_provider.get(prov, [])
            if chats:
                lines.append("• Channels:")
                for c in chats:
                    lines.append(f"  - <code>{c}</code>")
            else:
                lines.append("• Channels: <i>NONE</i>")

            route = route_by_provider.get(prov)
            if route and route.get("is_active"):
                lines.append(
                    "• Target account: "
                    f"<code>{route['account_id']}</code> "
                    f"({route['broker']}/{route['platform']}/{route['kind']}) — {route['label']}"
                )
            elif route:
                lines.append("• Target account: <i>configured but inactive</i>")
            else:
                lines.append("• Target account: <i>NONE</i>")

        return "\n".join(lines)
