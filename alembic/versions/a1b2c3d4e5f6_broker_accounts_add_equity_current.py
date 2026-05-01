"""broker_accounts add equity_current

Revision ID: a1b2c3d4e5f6
Revises: f2821d8a6363
"""

from __future__ import annotations

import sqlalchemy as sa
from alembic import op


revision: str = "a1b2c3d4e5f6"
down_revision: str | None = "f2821d8a6363"
branch_labels: str | None = None
depends_on: str | None = None


def upgrade() -> None:
    op.add_column(
        "broker_accounts",
        sa.Column(
            "equity_current",
            sa.Numeric(18, 2),
            nullable=True,
        ),
    )


def downgrade() -> None:
    op.drop_column("broker_accounts", "equity_current")
