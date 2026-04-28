"""trade families store broker symbol

Revision ID: 144b29cb0b0b
Revises: 3051ce82147d
"""
from __future__ import annotations

from alembic import op
import sqlalchemy as sa


revision: str = "144b29cb0b0b"
down_revision: str | None = "3051ce82147d"
branch_labels: str | None = None
depends_on: str | None = None


def upgrade() -> None:
    op.add_column("trade_families", sa.Column("broker_symbol", sa.Text(), nullable=True))
    op.create_index("idx_trade_families_broker_symbol", "trade_families", ["broker_symbol"], unique=False)


def downgrade() -> None:
    op.drop_index("idx_trade_families_broker_symbol", table_name="trade_families")
    op.drop_column("trade_families", "broker_symbol")
