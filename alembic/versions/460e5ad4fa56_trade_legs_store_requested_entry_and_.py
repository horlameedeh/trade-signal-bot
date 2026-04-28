"""trade legs store requested entry and placement delay

Revision ID: 460e5ad4fa56
Revises: 144b29cb0b0b
"""
from __future__ import annotations

from alembic import op
import sqlalchemy as sa


revision: str = "460e5ad4fa56"
down_revision: str | None = "144b29cb0b0b"
branch_labels: str | None = None
depends_on: str | None = None


def upgrade() -> None:
    op.add_column("trade_legs", sa.Column("requested_entry", sa.Numeric(18, 10), nullable=True))
    op.add_column("trade_legs", sa.Column("actual_fill_price", sa.Numeric(18, 10), nullable=True))
    op.add_column("trade_legs", sa.Column("placement_delay_ms", sa.Integer(), nullable=False, server_default="0"))


def downgrade() -> None:
    op.drop_column("trade_legs", "placement_delay_ms")
    op.drop_column("trade_legs", "actual_fill_price")
    op.drop_column("trade_legs", "requested_entry")
