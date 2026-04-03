"""routing_decisions message_id not null and unique

Revision ID: a672e703e9f3
Revises: cc7ddff2c2a4
Create Date: 2026-02-21 23:21:33.778795

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "a672e703e9f3"
down_revision = "cc7ddff2c2a4"
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Drop the existing partial unique index (same name)
    op.execute("DROP INDEX IF EXISTS uq_routing_decisions_chat_message;")

    # Enforce NOT NULL now that we verified there are no NULLs
    op.alter_column(
        "routing_decisions",
        "message_id",
        existing_type=sa.Integer(),
        nullable=False,
    )

    # Create a full unique index (works with ON CONFLICT (chat_id, message_id))
    op.create_index(
        "uq_routing_decisions_chat_message",
        "routing_decisions",
        ["chat_id", "message_id"],
        unique=True,
    )


def downgrade() -> None:
    # Revert to nullable
    op.execute("DROP INDEX IF EXISTS uq_routing_decisions_chat_message;")
    op.alter_column(
        "routing_decisions",
        "message_id",
        existing_type=sa.Integer(),
        nullable=True,
    )

    # Recreate the partial unique index (previous behavior)
    op.execute(
        """
        CREATE UNIQUE INDEX uq_routing_decisions_chat_message
        ON routing_decisions (chat_id, message_id)
        WHERE message_id IS NOT NULL;
        """
    )
