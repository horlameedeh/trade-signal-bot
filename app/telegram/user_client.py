"""
Checklist wrapper around the existing Telethon user client.

- Reads channels via Telethon (user login)
- Session stored outside repo (via app.ingest.telethon_client)

Exports:
  get_user_client()
  ensure_signed_in()
"""
from app.ingest.telethon_client import get_user_client, ensure_signed_in

__all__ = ["get_user_client", "ensure_signed_in"]
