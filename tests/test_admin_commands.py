import pytest
from sqlalchemy import text

from app.db.session import SessionLocal
from app.routing.admin_commands import handle_admin_command


pytestmark = pytest.mark.integration


@pytest.fixture
def db_session():
    with SessionLocal() as db:
        try:
            yield db
        finally:
            db.rollback()


def test_addchannel_sets_provider_code(db_session):
    chat_id = 777001
    db_session.execute(
        text("INSERT INTO telegram_chats (chat_id) VALUES (:c) ON CONFLICT (chat_id) DO NOTHING"),
        {"c": chat_id},
    )
    db_session.commit()

    reply = handle_admin_command(db_session, f"!addchannel fredtrading {chat_id}")
    assert reply is not None
    db_session.commit()

    provider = db_session.execute(
        text("SELECT provider_code FROM telegram_chats WHERE chat_id=:c"),
        {"c": chat_id},
    ).scalar()
    assert provider == "fredtrading"


def test_removechannel_clears_provider_code(db_session):
    chat_id = 777002
    db_session.execute(
        text(
            "INSERT INTO telegram_chats (chat_id, provider_code) VALUES (:c, 'fredtrading') "
            "ON CONFLICT (chat_id) DO UPDATE SET provider_code='fredtrading'"
        ),
        {"c": chat_id},
    )
    db_session.commit()

    reply = handle_admin_command(db_session, f"!removechannel fredtrading {chat_id}")
    assert reply is not None
    db_session.commit()

    provider = db_session.execute(
        text("SELECT provider_code FROM telegram_chats WHERE chat_id=:c"),
        {"c": chat_id},
    ).scalar()
    assert provider is None
