"""milestone2 routing tables

Revision ID: 17e06d84151d
Revises: 3c8cf7b1abf5
Create Date: 2026-02-21 21:39:40.946305

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


# revision identifiers, used by Alembic.
revision: str = '17e06d84151d'
down_revision: Union[str, Sequence[str], None] = '3c8cf7b1abf5'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    op.create_table(
        "provider_account_routes",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("provider_code", sa.Text(), nullable=False, unique=True),
        sa.Column(
            "broker_account_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("broker_accounts.account_id", ondelete="RESTRICT"),
            nullable=False,
        ),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.text("true")),
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
    )

    op.create_table(
        "routing_decisions",
        sa.Column("id", sa.BigInteger(), primary_key=True),
        sa.Column("telegram_message_id", sa.BigInteger(), nullable=True),
        sa.Column("chat_id", sa.BigInteger(), nullable=False),
        sa.Column("provider_code", sa.Text(), nullable=True),
        sa.Column("broker_account_id", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column(
            "decision",
            sa.Text(),
            nullable=False,
            comment='"ROUTED" | "IGNORED_UNKNOWN_CHAT" | "IGNORED_NO_ACCOUNT"',
        ),
        sa.Column("reason", sa.Text(), nullable=True),
        sa.Column("message_ts", sa.DateTime(timezone=True), nullable=True),
        sa.Column("raw_meta", postgresql.JSONB(astext_type=sa.Text()), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.text("now()"),
        ),
    )
    op.create_index("ix_routing_decisions_chat_id", "routing_decisions", ["chat_id"])
    op.create_index(
        "ix_routing_decisions_provider_code", "routing_decisions", ["provider_code"]
    )


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_index("ix_routing_decisions_provider_code", table_name="routing_decisions")
    op.drop_index("ix_routing_decisions_chat_id", table_name="routing_decisions")
    op.drop_table("routing_decisions")
    op.drop_table("provider_account_routes")
