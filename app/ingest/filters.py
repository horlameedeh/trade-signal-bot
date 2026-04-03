import os
from dataclasses import dataclass
from typing import Optional, Set


def _parse_csv_set(value: Optional[str]) -> Set[str]:
    if not value:
        return set()
    return {x.strip() for x in value.split(",") if x.strip()}


@dataclass(frozen=True)
class IngestAllowList:
    # Allow by numeric chat_id (preferred, stable)
    chat_ids: Set[int]
    # Allow by @username (fallback for channels with usernames)
    usernames: Set[str]
    # Optional: allow by exact title (least stable)
    titles: Set[str]

    control_chat_ids: Set[int]
    control_usernames: Set[str]
    control_titles: Set[str]


def load_allowlist_from_env() -> IngestAllowList:
    """
    ENV knobs (examples):
      TELEGRAM_PROVIDER_CHAT_IDS="-100111,-100222"
      TELEGRAM_PROVIDER_USERNAMES="fredtrading_signals,billionaireclub_x"
      TELEGRAM_PROVIDER_TITLES="Fredtrading Forex Live,BILLIONAIRE CLUB 1"

      TELEGRAM_CONTROL_CHAT_IDS="-100999"
      TELEGRAM_CONTROL_USERNAMES="my_private_control_group"
      TELEGRAM_CONTROL_TITLES="Trade Bot Control"
    """
    provider_ids = {int(x) for x in _parse_csv_set(os.getenv("TELEGRAM_PROVIDER_CHAT_IDS")) if x}
    provider_usernames = _parse_csv_set(os.getenv("TELEGRAM_PROVIDER_USERNAMES"))
    provider_titles = _parse_csv_set(os.getenv("TELEGRAM_PROVIDER_TITLES"))

    control_ids = {int(x) for x in _parse_csv_set(os.getenv("TELEGRAM_CONTROL_CHAT_IDS")) if x}
    control_usernames = _parse_csv_set(os.getenv("TELEGRAM_CONTROL_USERNAMES"))
    control_titles = _parse_csv_set(os.getenv("TELEGRAM_CONTROL_TITLES"))

    return IngestAllowList(
        chat_ids=provider_ids,
        usernames={u.lstrip("@").lower() for u in provider_usernames},
        titles=provider_titles,
        control_chat_ids=control_ids,
        control_usernames={u.lstrip("@").lower() for u in control_usernames},
        control_titles=control_titles,
    )


def is_allowed_chat(
    allow: IngestAllowList,
    *,
    chat_id: int,
    username: Optional[str],
    title: Optional[str],
) -> bool:
    u = (username or "").lstrip("@").lower() or None

    if chat_id in allow.chat_ids:
        return True
    if u and u in allow.usernames:
        return True
    if title and title in allow.titles:
        return True

    # control also allowed (we ingest it too)
    if chat_id in allow.control_chat_ids:
        return True
    if u and u in allow.control_usernames:
        return True
    if title and title in allow.control_titles:
        return True

    return False


def is_control_chat(
    allow: IngestAllowList,
    *,
    chat_id: int,
    username: Optional[str],
    title: Optional[str],
) -> bool:
    u = (username or "").lstrip("@").lower() or None
    if chat_id in allow.control_chat_ids:
        return True
    if u and u in allow.control_usernames:
        return True
    if title and title in allow.control_titles:
        return True
    return False