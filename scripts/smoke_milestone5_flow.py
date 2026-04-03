from __future__ import annotations

import argparse
import json
import uuid

from sqlalchemy import text

from app.db.session import SessionLocal
from app.services.trade_writer import create_trade_family_and_legs
from app.services.update_matcher import match_trade_family_for_update
from app.services.update_applier import apply_update_to_family
from app.services.management import apply_be_at_tp1
from app.services.edit_handler import handle_edited_message
from app.parsing.parser import parse_message


def cleanup_smoke_rows(*, source_msg_pk: str, chat_id: int, edit_message_id: int) -> dict[str, int]:
    source_message_id = 900000 + (uuid.UUID(source_msg_pk).int % 99999)

    with SessionLocal() as db:
        deleted = {
            "trade_legs": db.execute(
                text(
                    """
                    DELETE FROM trade_legs
                    WHERE family_id IN (
                        SELECT family_id
                        FROM trade_families
                        WHERE source_msg_pk = CAST(:source_msg_pk AS uuid)
                    )
                    """
                ),
                {"source_msg_pk": source_msg_pk},
            ).rowcount
            or 0,
            "trade_families": db.execute(
                text(
                    """
                    DELETE FROM trade_families
                    WHERE source_msg_pk = CAST(:source_msg_pk AS uuid)
                    """
                ),
                {"source_msg_pk": source_msg_pk},
            ).rowcount
            or 0,
            "trade_plans": db.execute(
                text(
                    """
                    DELETE FROM trade_plans
                    WHERE intent_id IN (
                        SELECT intent_id
                        FROM trade_intents
                        WHERE source_msg_pk = CAST(:source_msg_pk AS uuid)
                    )
                    """
                ),
                {"source_msg_pk": source_msg_pk},
            ).rowcount
            or 0,
            "trade_intents": db.execute(
                text(
                    """
                    DELETE FROM trade_intents
                    WHERE source_msg_pk = CAST(:source_msg_pk AS uuid)
                    """
                ),
                {"source_msg_pk": source_msg_pk},
            ).rowcount
            or 0,
            "telegram_messages": db.execute(
                text(
                    """
                    DELETE FROM telegram_messages
                    WHERE msg_pk = CAST(:source_msg_pk AS uuid)
                       OR (chat_id = :chat_id AND message_id = :source_message_id)
                       OR (chat_id = :chat_id AND message_id = :edit_message_id)
                    """
                ),
                {
                    "source_msg_pk": source_msg_pk,
                    "chat_id": chat_id,
                    "source_message_id": source_message_id,
                    "edit_message_id": edit_message_id,
                },
            ).rowcount
            or 0,
        }
        db.commit()

    return deleted


def seed_trade_intent_and_plan(source_msg_pk: str) -> None:
    chat_id = -1003254187278  # billionaire_club
    source_message_id = 900000 + (uuid.UUID(source_msg_pk).int % 99999)

    with SessionLocal() as db:
        db.execute(
            text(
                """
                INSERT INTO telegram_chats (chat_id, provider_code)
                VALUES (:chat_id, 'billionaire_club')
                ON CONFLICT (chat_id) DO UPDATE SET provider_code='billionaire_club'
                """
            ),
            {"chat_id": chat_id},
        )

        db.execute(
            text(
                """
                INSERT INTO telegram_messages (msg_pk, chat_id, message_id, text, raw_json)
                VALUES (CAST(:pk AS uuid), :chat_id, :source_message_id, 'seed trade', '{}'::jsonb)
                ON CONFLICT (chat_id, message_id) DO NOTHING
                """
            ),
            {"pk": source_msg_pk, "chat_id": chat_id, "source_message_id": source_message_id},
        )

        intent_id = str(uuid.uuid4())

        db.execute(
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
                  'billionaire_club',
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
                ON CONFLICT (source_msg_pk) DO NOTHING
                """
            ),
            {
                "intent_id": intent_id,
                "chat_id": chat_id,
                "pk": source_msg_pk,
                "source_message_id": source_message_id,
                "dedupe_hash": f"smoke-{source_msg_pk}",
            },
        )

        db.execute(
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
                  ARRAY['smoke']::text[]
                FROM trade_intents ti
                                WHERE ti.source_msg_pk = CAST(:pk AS uuid)
                  AND NOT EXISTS (
                    SELECT 1 FROM trade_plans tp WHERE tp.intent_id = ti.intent_id
                  )
                """
            ),
            {"pk": source_msg_pk},
        )

        db.commit()


def print_family_and_legs(family_id: str) -> None:
    with SessionLocal() as db:
        fam = db.execute(
            text(
                """
                SELECT family_id::text, provider, symbol_canonical, side, entry_price::text,
                       sl_price::text, tp_count, state, is_stub, management_rules, created_at
                FROM trade_families
                                WHERE family_id = CAST(:fid AS uuid)
                """
            ),
            {"fid": family_id},
        ).mappings().first()

        legs = db.execute(
            text(
                """
                SELECT leg_index, entry_price::text, sl_price::text, tp_price::text, state, lots::text
                FROM trade_legs
                WHERE family_id = CAST(:fid AS uuid)
                ORDER BY leg_index
                """
            ),
            {"fid": family_id},
        ).mappings().all()

    print("\n=== TRADE FAMILY ===")
    print(json.dumps(dict(fam), indent=2, default=str))
    print("\n=== TRADE LEGS ===")
    print(json.dumps([dict(x) for x in legs], indent=2, default=str))


def main() -> None:
    parser = argparse.ArgumentParser(description="Run Milestone 5 end-to-end smoke flow")
    parser.add_argument(
        "--auto-cleanup",
        action="store_true",
        help="Delete smoke-created rows at the end of a successful run",
    )
    parser.add_argument(
        "--keep-data",
        action="store_true",
        help="Keep smoke-created rows even if --auto-cleanup is provided",
    )
    args = parser.parse_args()

    chat_id = -1003254187278
    source_msg_pk = str(uuid.uuid4())
    source_message_id = 900000 + (uuid.UUID(source_msg_pk).int % 99999)

    print("1) Seeding intent + plan...")
    seed_trade_intent_and_plan(source_msg_pk)

    print("2) Creating family + legs...")
    tw = create_trade_family_and_legs(
        source_msg_pk=source_msg_pk,
        total_lot="0.30",
    )
    print("TradeWriterResult:", tw)

    family_id = tw.family_id
    print_family_and_legs(family_id)

    print("\n3) Matching update to family...")
    match = match_trade_family_for_update(
        provider="billionaire_club",
        symbol="XAUUSD",
        side="buy",
    )
    print("MatchResult:", match)

    print("\n4) Applying BE update...")
    parsed_update = parse_message(
        "billionaire_club",
        "Position is running nicely! I will Move stop loss to break even!",
    )
    apply_result = apply_update_to_family(
        family_id=family_id,
        parsed=parsed_update,
    )
    print("ApplyUpdateResult:", apply_result)
    print_family_and_legs(family_id)

    print("\n5) Closing TP1 leg and applying BE_AT_TP1 management...")
    with SessionLocal() as db:
        db.execute(
            text(
                """
                UPDATE trade_legs
                SET state = 'CLOSED'
                                WHERE family_id = CAST(:fid AS uuid)
                  AND leg_index = 1
                """
            ),
            {"fid": family_id},
        )
        db.commit()

    mgmt = apply_be_at_tp1(family_id=family_id)
    print("ManagementResult:", mgmt)
    print_family_and_legs(family_id)

    print("\n6) Simulating edited Telegram update message...")
    edit_message_id = source_message_id + 1
    with SessionLocal() as db:
        db.execute(
            text(
                """
                INSERT INTO telegram_messages (msg_pk, chat_id, message_id, text, raw_json, is_edited)
                VALUES (
                  gen_random_uuid(),
                  -1003254187278,
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
            {"edit_message_id": edit_message_id},
        )
        db.commit()

    edit_result = handle_edited_message(chat_id=-1003254187278, message_id=edit_message_id)
    print("EditHandlingResult:", edit_result)
    print_family_and_legs(family_id)

    print("\n✅ Milestone 5 smoke flow complete.")
    print(f"family_id={family_id}")
    print(f"source_msg_pk={source_msg_pk}")
    print(
        "cleanup_command="
        f"PYTHONPATH=. python scripts/cleanup_milestone5_smoke.py {source_msg_pk} --execute"
    )

    cleanup_enabled = args.auto_cleanup and not args.keep_data
    if args.auto_cleanup and args.keep_data:
        print("note=--keep-data provided; skipping auto cleanup")

    if cleanup_enabled:
        deleted = cleanup_smoke_rows(
            source_msg_pk=source_msg_pk,
            chat_id=chat_id,
            edit_message_id=edit_message_id,
        )
        print("auto_cleanup_deleted=", deleted)


if __name__ == "__main__":
    main()
