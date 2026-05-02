"""add telegram provider channels

Revision ID: c42bc47738bd
Revises: c6f3628562cb
Create Date: 2026-05-02 17:56:26.966365

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


# revision identifiers, used by Alembic.
revision = "c42bc47738bd"
down_revision = "c6f3628562cb"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "telegram_provider_channels",
        sa.Column(
            "channel_id",
            postgresql.UUID(as_uuid=True),
            primary_key=True,
            server_default=sa.text("gen_random_uuid()"),
        ),
        sa.Column("provider_code", sa.Text(), nullable=False),
        sa.Column("chat_id", sa.BigInteger(), nullable=False),
        sa.Column("title", sa.Text(), nullable=True),
        sa.Column("username", sa.Text(), nullable=True),
        sa.Column("channel_type", sa.Text(), nullable=False, server_default="signal"),
        sa.Column("is_enabled", sa.Boolean(), nullable=False, server_default=sa.text("true")),
        sa.Column("ingestion_mode", sa.Text(), nullable=False, server_default="telethon"),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.text("now()"),
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.text("now()"),
        ),
        sa.UniqueConstraint("chat_id", name="uq_telegram_provider_channels_chat_id"),
    )

    op.create_index(
        "idx_telegram_provider_channels_provider",
        "telegram_provider_channels",
        ["provider_code"],
    )


def downgrade() -> None:
    op.drop_index("idx_telegram_provider_channels_provider", table_name="telegram_provider_channels")
    op.drop_table("telegram_provider_channels")
