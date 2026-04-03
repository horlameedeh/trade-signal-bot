"""trade intents and updates idempotency indexes

Revision ID: 2b3680d79745
Revises: 8d46443bb1a4
"""

from __future__ import annotations

from alembic import op
import sqlalchemy as sa

revision: str = "2b3680d79745"
down_revision: str | None = "8d46443bb1a4"
branch_labels: str | None = None
depends_on: str | None = None


def upgrade() -> None:
    op.create_index(
        "uq_trade_intents_source_msg_pk",
        "trade_intents",
        ["source_msg_pk"],
        unique=True,
    )
    op.create_index(
        "uq_trade_updates_source_msg_pk",
        "trade_updates",
        ["source_msg_pk"],
        unique=True,
    )


def downgrade() -> None:
    op.drop_index("uq_trade_updates_source_msg_pk", table_name="trade_updates")
    op.drop_index("uq_trade_intents_source_msg_pk", table_name="trade_intents")
