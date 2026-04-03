"""link routing_decisions to telegram_messages msg_pk

Revision ID: da00f7f68e77
Revises: a672e703e9f3
Create Date: 2026-02-23 21:06:22.879709

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


# revision identifiers, used by Alembic.
revision: str = 'da00f7f68e77'
down_revision: Union[str, Sequence[str], None] = 'a672e703e9f3'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""

    # 1) Add new UUID column (nullable for safe rollout)
    op.add_column(
        "routing_decisions",
        sa.Column("telegram_msg_pk", postgresql.UUID(as_uuid=True), nullable=True),
    )

    # 2) Backfill by joining on (chat_id, message_id)
    op.execute(
        """
        UPDATE routing_decisions rd
        SET telegram_msg_pk = tm.msg_pk
        FROM telegram_messages tm
        WHERE rd.telegram_msg_pk IS NULL
          AND tm.chat_id = rd.chat_id
          AND tm.message_id = rd.message_id;
        """
    )

    # 3) Add FK constraint
    op.create_foreign_key(
        "fk_routing_decisions_telegram_msg_pk",
        "routing_decisions",
        "telegram_messages",
        ["telegram_msg_pk"],
        ["msg_pk"],
        ondelete="SET NULL",
    )

    # 4) Index for faster joins/debugging
    op.create_index(
        "ix_routing_decisions_telegram_msg_pk",
        "routing_decisions",
        ["telegram_msg_pk"],
        unique=False,
    )


def downgrade() -> None:
    """Downgrade schema."""

    op.drop_index("ix_routing_decisions_telegram_msg_pk", table_name="routing_decisions")
    op.drop_constraint(
        "fk_routing_decisions_telegram_msg_pk",
        "routing_decisions",
        type_="foreignkey",
    )
    op.drop_column("routing_decisions", "telegram_msg_pk")
