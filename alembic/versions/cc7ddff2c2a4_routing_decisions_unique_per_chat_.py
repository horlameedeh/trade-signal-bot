"""routing_decisions unique per chat message

Revision ID: cc7ddff2c2a4
Revises: 17e06d84151d
Create Date: 2026-02-21 23:03:25.149951

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "cc7ddff2c2a4"
down_revision = "17e06d84151d"
branch_labels = None
depends_on = None


def upgrade() -> None:
    # 1) Add message_id column (nullable for safe rollout)
    op.add_column("routing_decisions", sa.Column("message_id", sa.Integer(), nullable=True))

    # 2) Backfill message_id from raw_meta->>'message_id' where possible
    op.execute(
        """
        UPDATE routing_decisions
        SET message_id = NULLIF((raw_meta->>'message_id'), '')::int
        WHERE message_id IS NULL
          AND raw_meta ? 'message_id';
        """
    )

    # 3) Enforce uniqueness for rows that have message_id
    # One routing decision per (chat_id, message_id)
    op.execute(
        """
        CREATE UNIQUE INDEX IF NOT EXISTS uq_routing_decisions_chat_message
        ON routing_decisions (chat_id, message_id)
        WHERE message_id IS NOT NULL;
        """
    )


def downgrade() -> None:
    op.execute("DROP INDEX IF EXISTS uq_routing_decisions_chat_message;")
    op.drop_column("routing_decisions", "message_id")