from __future__ import annotations

import argparse
import uuid

from sqlalchemy import text

from app.db.session import SessionLocal


DEFAULT_CHAT_ID = -1003254187278
BASE_MESSAGE_ID = 900000
MESSAGE_ID_MOD = 99999


def _derive_message_ids(source_msg_pk: str) -> tuple[int, int]:
    source_message_id = BASE_MESSAGE_ID + (uuid.UUID(source_msg_pk).int % MESSAGE_ID_MOD)
    edit_message_id = source_message_id + 1
    return source_message_id, edit_message_id


def _count_rows(source_msg_pk: str, chat_id: int, source_message_id: int, edit_message_id: int) -> dict[str, int]:
    with SessionLocal() as db:
        counts = {
            "trade_legs": db.execute(
                text(
                    """
                    SELECT COUNT(*)
                    FROM trade_legs tl
                    JOIN trade_families tf ON tf.family_id = tl.family_id
                    WHERE tf.source_msg_pk = CAST(:source_msg_pk AS uuid)
                    """
                ),
                {"source_msg_pk": source_msg_pk},
            ).scalar()
            or 0,
            "trade_families": db.execute(
                text(
                    """
                    SELECT COUNT(*)
                    FROM trade_families
                    WHERE source_msg_pk = CAST(:source_msg_pk AS uuid)
                    """
                ),
                {"source_msg_pk": source_msg_pk},
            ).scalar()
            or 0,
            "trade_plans": db.execute(
                text(
                    """
                    SELECT COUNT(*)
                    FROM trade_plans tp
                    JOIN trade_intents ti ON ti.intent_id = tp.intent_id
                    WHERE ti.source_msg_pk = CAST(:source_msg_pk AS uuid)
                    """
                ),
                {"source_msg_pk": source_msg_pk},
            ).scalar()
            or 0,
            "trade_intents": db.execute(
                text(
                    """
                    SELECT COUNT(*)
                    FROM trade_intents
                    WHERE source_msg_pk = CAST(:source_msg_pk AS uuid)
                    """
                ),
                {"source_msg_pk": source_msg_pk},
            ).scalar()
            or 0,
            "telegram_messages": db.execute(
                text(
                    """
                    SELECT COUNT(*)
                    FROM telegram_messages
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
            ).scalar()
            or 0,
        }
    return counts


def cleanup_smoke_run(*, source_msg_pk: str, chat_id: int) -> dict[str, int]:
    source_message_id, edit_message_id = _derive_message_ids(source_msg_pk)

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


def main() -> None:
    parser = argparse.ArgumentParser(description="Clean up rows created by scripts/smoke_milestone5_flow.py")
    parser.add_argument("source_msg_pk", help="The source_msg_pk printed by the smoke script")
    parser.add_argument("--chat-id", type=int, default=DEFAULT_CHAT_ID, help="Telegram chat_id used for the smoke run")
    parser.add_argument("--execute", action="store_true", help="Actually delete rows. Without this flag, only show what would be removed.")
    args = parser.parse_args()

    source_message_id, edit_message_id = _derive_message_ids(args.source_msg_pk)
    counts = _count_rows(args.source_msg_pk, args.chat_id, source_message_id, edit_message_id)

    print(f"source_msg_pk={args.source_msg_pk}")
    print(f"chat_id={args.chat_id}")
    print(f"source_message_id={source_message_id}")
    print(f"edit_message_id={edit_message_id}")
    print("rows:")
    for table_name, count in counts.items():
        print(f"  {table_name}: {count}")

    if not args.execute:
        print("\nDry run only. Re-run with --execute to delete these rows.")
        return

    deleted = cleanup_smoke_run(source_msg_pk=args.source_msg_pk, chat_id=args.chat_id)
    print("\ndeleted:")
    for table_name, count in deleted.items():
        print(f"  {table_name}: {count}")


if __name__ == "__main__":
    main()
