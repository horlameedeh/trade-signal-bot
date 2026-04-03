import uuid
import pytest
from sqlalchemy import text

from app.db.session import SessionLocal
from app.parsing.parser import parse_message
from app.parsing.persist import persist_parsed_signal


pytestmark = pytest.mark.integration


@pytest.fixture
def db_session():
    with SessionLocal() as db:
        try:
            yield db
        finally:
            db.rollback()


def _ensure_chat_and_msg(db_session, *, chat_id: int, message_id: int):
    db_session.execute(
        text("INSERT INTO telegram_chats (chat_id) VALUES (:c) ON CONFLICT (chat_id) DO NOTHING"),
        {"c": chat_id},
    )
    existing = db_session.execute(
        text(
            """
            SELECT msg_pk
            FROM telegram_messages
            WHERE chat_id = :c AND message_id = :mid
            LIMIT 1
            """
        ),
        {"c": chat_id, "mid": message_id},
    ).scalar()

    if existing:
        msg_pk = str(existing)
    else:
        msg_pk = str(uuid.uuid4())
        db_session.execute(
            text(
                """
                INSERT INTO telegram_messages (msg_pk, chat_id, message_id, raw_json)
                VALUES (CAST(:pk AS uuid), :c, :mid, '{}'::jsonb)
                """
            ),
            {"pk": msg_pk, "c": chat_id, "mid": message_id},
        )
    db_session.commit()
    return msg_pk


def test_persist_new_trade_creates_trade_intent(db_session):
    msg_pk = _ensure_chat_and_msg(db_session, chat_id=-1001239815745, message_id=900001)

    sig = parse_message("fredtrading", "BUY GOLD now\\nSL 2010\\nTP 2030 2040")
    persist_parsed_signal(
        source_msg_pk=msg_pk,
        provider_code="fredtrading",
        broker_account_id=None,
        parsed=sig,
    )

    row = db_session.execute(
        text(
            """
            SELECT provider, chat_id, source_msg_pk, symbol_canonical, side, order_type, is_unofficial
            FROM trade_intents
            WHERE source_msg_pk = CAST(:pk AS uuid)
            """
        ),
        {"pk": msg_pk},
    ).mappings().first()

    assert row is not None
    assert row["provider"] == "fredtrading"
    assert row["chat_id"] == -1001239815745
    assert str(row["source_msg_pk"]) == msg_pk
    assert row["symbol_canonical"] == "XAUUSD"
    assert row["side"] == "buy"
    assert row["order_type"] == "market"
    assert row["is_unofficial"] is False


def test_persist_update_creates_trade_update(db_session):
    msg_pk = _ensure_chat_and_msg(db_session, chat_id=-1002298510219, message_id=900002)

    sig = parse_message("mubeen", "BTC update: TP1 to 53000")
    persist_parsed_signal(
        source_msg_pk=msg_pk,
        provider_code="mubeen",
        broker_account_id=None,
        parsed=sig,
    )

    row = db_session.execute(
        text(
            """
            SELECT provider, chat_id, source_msg_pk, kind, symbol_canonical
            FROM trade_updates
            WHERE source_msg_pk = CAST(:pk AS uuid)
            """
        ),
        {"pk": msg_pk},
    ).mappings().first()

    assert row is not None
    assert row["provider"] == "mubeen"
    assert row["chat_id"] == -1002298510219
    assert str(row["source_msg_pk"]) == msg_pk
    assert row["kind"] == "move_tp"
    assert row["symbol_canonical"] == "BTCUSD"


def test_persist_is_idempotent_by_source_msg_pk(db_session):
    msg_pk = _ensure_chat_and_msg(db_session, chat_id=-1001239815745, message_id=900003)

    sig = parse_message("fredtrading", "BUY GOLD now\\nSL 2010\\nTP 2030")
    persist_parsed_signal(
        source_msg_pk=msg_pk,
        provider_code="fredtrading",
        broker_account_id=None,
        parsed=sig,
    )
    persist_parsed_signal(
        source_msg_pk=msg_pk,
        provider_code="fredtrading",
        broker_account_id=None,
        parsed=sig,
    )

    count = db_session.execute(
        text("SELECT COUNT(*) FROM trade_intents WHERE source_msg_pk = CAST(:pk AS uuid)"),
        {"pk": msg_pk},
    ).scalar()
    assert count == 1
