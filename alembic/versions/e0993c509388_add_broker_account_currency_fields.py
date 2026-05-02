"""add broker account currency fields

Revision ID: e0993c509388
Revises: 71c5a3c5ec52
Create Date: 2026-05-03 00:45:07.927480

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "e0993c509388"
down_revision = "71c5a3c5ec52"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "broker_accounts",
        sa.Column("account_currency", sa.Text(), nullable=False, server_default="GBP"),
    )
    op.add_column(
        "broker_accounts",
        sa.Column("account_size", sa.Numeric(18, 2), nullable=True),
    )

    op.execute(
        """
        UPDATE broker_accounts
        SET account_size = COALESCE(equity_start, equity_current, 10000)
        WHERE account_size IS NULL
    """
    )


def downgrade() -> None:
    op.drop_column("broker_accounts", "account_size")
    op.drop_column("broker_accounts", "account_currency")
