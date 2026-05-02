import uuid

from app.telegram.telethon_ingestion import persist_telegram_message


def _unique_chat_id() -> int:
    # Keep IDs in BIGINT range and avoid collisions with stale rows from prior test runs.
    return -((uuid.uuid4().int % 9_000_000_000_000_000_000) or 1)


def test_persist_telegram_message_dedupes():
    chat_id = _unique_chat_id()

    first = persist_telegram_message(
        provider_code="test_provider",
        chat_id=chat_id,
        message_id=123,
        text_value="BUY XAUUSD",
        raw_json={"test": True},
        dry_run=True,
    )

    second = persist_telegram_message(
        provider_code="test_provider",
        chat_id=chat_id,
        message_id=123,
        text_value="BUY XAUUSD",
        raw_json={"test": True},
        dry_run=True,
    )

    assert first.inserted is True
    assert second.inserted is False
    assert first.dry_run is True


def test_persist_telegram_message_allows_new_message_id():
    chat_id = _unique_chat_id()

    first = persist_telegram_message(
        provider_code="test_provider",
        chat_id=chat_id,
        message_id=123,
        text_value="BUY XAUUSD",
        dry_run=True,
    )

    second = persist_telegram_message(
        provider_code="test_provider",
        chat_id=chat_id,
        message_id=124,
        text_value="SELL XAUUSD",
        dry_run=True,
    )

    assert first.inserted is True
    assert second.inserted is True
