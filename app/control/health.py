from __future__ import annotations

from sqlalchemy import text

from app.db.session import SessionLocal


def build_health_text() -> str:
    with SessionLocal() as db:
        db_ok = True
        try:
            db.execute(text("SELECT 1"))
        except Exception:
            db_ok = False

        mapped_chats = (
            db.execute(text("SELECT COUNT(*) FROM telegram_chats WHERE provider_code IS NOT NULL")).scalar()
            or 0
        )

        active_routes = (
            db.execute(text("SELECT COUNT(*) FROM provider_account_routes WHERE is_active = true")).scalar() or 0
        )

        last_msg = db.execute(text("SELECT MAX(sent_at) FROM telegram_messages")).scalar()

        last_decision = db.execute(text("SELECT MAX(created_at) FROM routing_decisions")).scalar()

        lines = [
            "🩺 <b>Health</b>",
            f"• DB: {'OK ✅' if db_ok else 'FAIL ❌'}",
            f"• Mapped chats: <b>{mapped_chats}</b>",
            f"• Active provider routes: <b>{active_routes}</b>",
            f"• Last telegram message: <code>{last_msg}</code>",
            f"• Last routing decision: <code>{last_decision}</code>",
        ]
        return "\n".join(lines)
