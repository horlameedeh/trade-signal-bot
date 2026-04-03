import os
from pathlib import Path
from telethon import TelegramClient

SESSION_NAME = os.getenv("TELETHON_SESSION_NAME", "tradebot")

def _default_session_dir() -> Path:
    # Checklist target (macOS):
    # ~/Library/Application Support/tradebot/
    base = Path.home() / "Library" / "Application Support" / "tradebot" / "telethon"
    override = os.getenv("TELETHON_SESSION_DIR")
    return Path(override) if override else base

def _chmod_session_dir(session_dir: Path) -> None:
    try:
        session_dir.mkdir(parents=True, exist_ok=True)
        session_dir.chmod(0o700)
    except Exception:
        # Don't hard-fail; just avoid crashing the app
        pass

def _chmod_session_files(session_dir: Path, session_name: str) -> None:
    # Telethon may create multiple files (e.g. .session, .session-journal)
    try:
        for p in session_dir.glob(session_name + ".session*"):
            try:
                p.chmod(0o600)
            except Exception:
                pass
    except Exception:
        pass

def get_user_client() -> TelegramClient:
    api_id = int(os.environ["TELEGRAM_API_ID"])
    api_hash = os.environ["TELEGRAM_API_HASH"]

    session_dir = _default_session_dir()
    _chmod_session_dir(session_dir)

    # Telethon accepts a session "string"; if it's a path, it writes <path>.session
    session_path = session_dir / SESSION_NAME
    return TelegramClient(str(session_path), api_id, api_hash)

async def ensure_signed_in(client: TelegramClient) -> None:
    await client.start()
    # After start, session files should exist; enforce perms
    session_dir = _default_session_dir()
    _chmod_session_files(session_dir, SESSION_NAME)
