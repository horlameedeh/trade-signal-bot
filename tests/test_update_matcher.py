import uuid

import pytest
from sqlalchemy import text

from app.db.session import SessionLocal
from app.services.update_matcher import match_trade_family_for_update


pytestmark = pytest.mark.integration


@pytest.fixture
def db_session():
    with SessionLocal() as db:
        try:
            yield db
        finally:
            db.rollback()


def _seed_family(db_session, *, state: str, symbol: str):
    family_id = str(uuid.uuid4())
    source_msg_pk = str(uuid.uuid4())
    intent_id = str(uuid.uuid4())
    chat_id = -1001239815745
    message_id = 990000 + (uuid.UUID(source_msg_pk).int % 100000)

    db_session.execute(
        text(
            """
            INSERT INTO telegram_chats (chat_id, provider_code)
            VALUES (:chat_id, 'fredtrading')
            ON CONFLICT (chat_id) DO UPDATE SET provider_code='fredtrading'
            """
        ),
        {"chat_id": chat_id},
    )

    db_session.execute(
        text(
            """
            INSERT INTO telegram_messages (msg_pk, chat_id, message_id, text, raw_json)
            VALUES (CAST(:source_msg_pk AS uuid), :chat_id, :message_id, 'seed', '{}'::jsonb)
            ON CONFLICT (chat_id, message_id) DO NOTHING
            """
        ),
        {"source_msg_pk": source_msg_pk, "chat_id": chat_id, "message_id": message_id},
    )

    db_session.execute(
        text(
            """
            INSERT INTO trade_intents (
              intent_id,
              provider,
              chat_id,
              source_msg_pk,
              source_message_id,
              dedupe_hash,
              parse_confidence,
              symbol_canonical,
              symbol_raw,
              side,
              order_type,
              entry_price,
              sl_price,
              tp_prices,
              has_runner,
              risk_tag,
              is_scalp,
              is_swing,
              is_unofficial,
              reenter_tag,
              instructions,
              meta
            )
            VALUES (
              CAST(:intent_id AS uuid),
              'fredtrading',
              :chat_id,
              CAST(:source_msg_pk AS uuid),
              :message_id,
              :dedupe_hash,
              0.950,
              'XAUUSD',
              'XAUUSD',
              'buy',
              'market',
              2025,
              2010,
              ARRAY[2030]::numeric(18,10)[],
              false,
              'normal',
              false,
              false,
              false,
              false,
              'seed',
              '{}'::jsonb
            )
            ON CONFLICT (source_msg_pk) DO NOTHING
            """
        ),
        {
            "intent_id": intent_id,
            "chat_id": chat_id,
            "source_msg_pk": source_msg_pk,
            "message_id": message_id,
            "dedupe_hash": f"seed-{source_msg_pk}",
        },
    )

    db_session.execute(
        text(
            """
            INSERT INTO trade_families (
              family_id,
              provider,
              symbol_canonical,
              side,
              state,
              source_msg_pk,
              intent_id
            )
            VALUES (
                            CAST(:family_id AS uuid),
              'fredtrading',
                            :symbol,
              'buy',
              :state,
                            CAST(:source_msg_pk AS uuid),
                            CAST(:intent_id AS uuid)
            )
            """
        ),
                {
                        "family_id": family_id,
                        "symbol": symbol,
                        "state": state,
                        "source_msg_pk": source_msg_pk,
                        "intent_id": intent_id,
                },
    )
    db_session.commit()
    return family_id


def test_match_pending_update_first(db_session):
    symbol = f"XAUUSD-PENDING-{uuid.uuid4().hex[:8]}"
    fid = _seed_family(db_session, state="PENDING_UPDATE", symbol=symbol)

    result = match_trade_family_for_update(
        provider="fredtrading",
        symbol=symbol,
        side="buy",
    )

    assert result.family_id == fid
    assert result.requires_selection is False


def test_match_open_when_no_pending(db_session):
    symbol = f"XAUUSD-OPEN-{uuid.uuid4().hex[:8]}"
    fid = _seed_family(db_session, state="OPEN", symbol=symbol)

    result = match_trade_family_for_update(
        provider="fredtrading",
        symbol=symbol,
        side="buy",
    )

    assert result.family_id == fid
    assert result.requires_selection is False


def test_multiple_candidates_require_selection(db_session):
    symbol = f"XAUUSD-MULTI-{uuid.uuid4().hex[:8]}"
    f1 = _seed_family(db_session, state="OPEN", symbol=symbol)
    f2 = _seed_family(db_session, state="OPEN", symbol=symbol)

    result = match_trade_family_for_update(
        provider="fredtrading",
        symbol=symbol,
        side="buy",
    )

    assert result.family_id is None
    assert result.requires_selection is True
    assert len(result.candidates) == 2
