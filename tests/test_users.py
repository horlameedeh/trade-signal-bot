import pytest
from sqlalchemy import text

from app.db.session import SessionLocal
from app.services.users import (
    get_or_create_user,
    get_user_by_telegram_id,
    link_control_chat,
    resolve_user_from_control_chat,
)


@pytest.fixture
def db_session():
    with SessionLocal() as db:
        try:
            db.execute(text("DELETE FROM user_control_chats WHERE telegram_chat_id IN (111111, 222222)"))
            db.execute(text("DELETE FROM users WHERE telegram_user_id IN (111, 222)"))
            db.commit()
            yield db
        finally:
            db.execute(text("DELETE FROM user_control_chats WHERE telegram_chat_id IN (111111, 222222)"))
            db.execute(text("DELETE FROM users WHERE telegram_user_id IN (111, 222)"))
            db.commit()


def test_get_or_create_user(db_session):
    user = get_or_create_user(telegram_user_id=111, display_name="Alice")

    assert user.telegram_user_id == 111
    assert user.display_name == "Alice"
    assert user.role == "user"
    assert user.is_active is True

    loaded = get_user_by_telegram_id(telegram_user_id=111)
    assert loaded is not None
    assert loaded.user_id == user.user_id


def test_link_and_resolve_control_chat(db_session):
    user = get_or_create_user(telegram_user_id=111, display_name="Alice")

    link_control_chat(user_id=user.user_id, telegram_chat_id=111111, label="alice-control")

    resolved = resolve_user_from_control_chat(telegram_chat_id=111111)

    assert resolved is not None
    assert resolved.user_id == user.user_id


def test_two_users_resolve_independently(db_session):
    alice = get_or_create_user(telegram_user_id=111, display_name="Alice")
    bob = get_or_create_user(telegram_user_id=222, display_name="Bob")

    link_control_chat(user_id=alice.user_id, telegram_chat_id=111111, label="alice-control")
    link_control_chat(user_id=bob.user_id, telegram_chat_id=222222, label="bob-control")

    resolved_alice = resolve_user_from_control_chat(telegram_chat_id=111111)
    resolved_bob = resolve_user_from_control_chat(telegram_chat_id=222222)

    assert resolved_alice is not None
    assert resolved_bob is not None
    assert resolved_alice.user_id == alice.user_id
    assert resolved_bob.user_id == bob.user_id
    assert resolved_alice.user_id != resolved_bob.user_id
