import uuid

import pytest
from sqlalchemy import text

from app.db.session import SessionLocal
from app.services.trade_writer import create_trade_family_and_legs
from app.services.edit_handler import handle_edited_message


pytestmark = pytest.mark.integration


@pytest.fixture
def db_session():
    with SessionLocal() as db:
        try:
            yield db
        finally:
            db.rollback()


def _seed_family_and_update_message(db_session, *, provider: str = "billionaire_club"):
    chat_id = -1003254187278
    source_msg_pk = str(uuid.uuid4())
    intent_id = str(uuid.uuid4())
    source_message_id = 900000 + (uuid.UUID(source_msg_pk).int % 99999)
    edit_message_id = source_message_id + 1

    db_session.execute(
        text(
            """
            INSERT INTO telegram_chats (chat_id, provider_code)
            VALUES (:chat_id, :provider)
            ON CONFLICT (chat_id) DO UPDATE SET provider_code = EXCLUDED.provider_code
            """
        ),
        {"chat_id": chat_id, "provider": provider},
    )

    # original source message for trade family
    db_session.execute(
        text(
            """
            INSERT INTO telegram_messages (msg_pk, chat_id, message_id, text, raw_json)
            VALUES (CAST(:pk AS uuid), :chat_id, :source_message_id, 'seed trade', '{}'::jsonb)
            ON CONFLICT (chat_id, message_id) DO NOTHING
            """
        ),
        {"pk": source_msg_pk, "chat_id": chat_id, "source_message_id": source_message_id},
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
              :provider,
              :chat_id,
                            CAST(:pk AS uuid),
                            :source_message_id,
              :dedupe_hash,
              0.950,
              'XAUUSD',
              'XAUUSD',
              'buy',
              'market',
              4922,
              4916,
              ARRAY[4925,4928,4934]::numeric(18,10)[],
              false,
              'normal',
              false,
              false,
              false,
              false,
              'seed',
              '{}'::jsonb
            )
            """
        ),
        {
            "intent_id": intent_id,
            "provider": provider,
            "chat_id": chat_id,
            "pk": source_msg_pk,
            "source_message_id": source_message_id,
            "dedupe_hash": f"seed-{source_msg_pk}",
        },
    )

    db_session.execute(
        text(
            """
            INSERT INTO trade_plans (
              intent_id,
              account_id,
              policy_outcome,
              requires_approval,
              policy_reasons
            )
            SELECT
              ti.intent_id,
              (
                SELECT ba.account_id
                FROM broker_accounts ba
                WHERE ba.is_active = true
                LIMIT 1
              ),
                            'allow'::policy_outcome,
              false,
              ARRAY['seed']::text[]
            FROM trade_intents ti
                        WHERE ti.source_msg_pk = CAST(:pk AS uuid)
            """
        ),
        {"pk": source_msg_pk},
    )

    db_session.commit()

    family_id = create_trade_family_and_legs(
        source_msg_pk=source_msg_pk,
        total_lot="0.30",
    ).family_id

    # edited/update message to be handled later
    edit_msg_pk = str(uuid.uuid4())
    db_session.execute(
        text(
            """
            INSERT INTO telegram_messages (msg_pk, chat_id, message_id, text, raw_json, is_edited)
            VALUES (
                            CAST(:pk AS uuid),
              :chat_id,
                            :edit_message_id,
              'Position is running nicely! I will Move stop loss to break even!',
              '{}'::jsonb,
              true
            )
            ON CONFLICT (chat_id, message_id) DO UPDATE
            SET text = EXCLUDED.text,
                is_edited = true
            """
        ),
        {"pk": edit_msg_pk, "chat_id": chat_id, "edit_message_id": edit_message_id},
    )
    db_session.commit()

    return family_id, chat_id, edit_message_id


def test_edited_message_reruns_update_logic(db_session):
    family_id, chat_id, message_id = _seed_family_and_update_message(db_session)

    result = handle_edited_message(chat_id=chat_id, message_id=message_id)

    assert result.applied is True
    assert result.matched_family_id == family_id
    assert result.reason == "ok"

    fam = db_session.execute(
        text("SELECT entry_price::text, sl_price::text FROM trade_families WHERE family_id = CAST(:fid AS uuid)"),
        {"fid": family_id},
    ).mappings().first()

    assert fam["entry_price"] == fam["sl_price"]


def test_non_update_edit_is_noop(db_session):
    chat_id = -1003254187278

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
            INSERT INTO telegram_messages (msg_pk, chat_id, message_id, text, raw_json, is_edited)
            VALUES (
              gen_random_uuid(),
              :chat_id,
              950010,
              'hello just info',
              '{}'::jsonb,
              true
            )
            ON CONFLICT (chat_id, message_id) DO UPDATE
            SET text = EXCLUDED.text,
                is_edited = true
            """
        ),
        {"chat_id": chat_id},
    )
    db_session.commit()

    result = handle_edited_message(chat_id=chat_id, message_id=950010)
    assert result.applied is False
    assert result.reason == "edited_message_not_update"
