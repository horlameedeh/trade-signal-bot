"""add provider live ingestion controls

Revision ID: 71c5a3c5ec52
Revises: c42bc47738bd
Create Date: 2026-05-02 21:35:25.414724

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '71c5a3c5ec52'
down_revision: Union[str, Sequence[str], None] = 'c42bc47738bd'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    op.add_column(
        "telegram_provider_channels",
        sa.Column("allow_live_execution", sa.Boolean(), nullable=False, server_default=sa.text("false")),
    )
    op.add_column(
        "telegram_provider_channels",
        sa.Column("notes", sa.Text(), nullable=True),
    )


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_column("telegram_provider_channels", "notes")
    op.drop_column("telegram_provider_channels", "allow_live_execution")
