"""add_is_active_to_telegram_chats

Revision ID: c6f3628562cb
Revises: d7c2c721f9ec
Create Date: 2026-05-02 01:43:33.540698

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'c6f3628562cb'
down_revision: Union[str, Sequence[str], None] = 'd7c2c721f9ec'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    op.execute(
        """
        ALTER TABLE telegram_chats
        ADD COLUMN IF NOT EXISTS is_active BOOLEAN NOT NULL DEFAULT TRUE
        """
    )


def downgrade() -> None:
    """Downgrade schema."""
    op.execute("ALTER TABLE telegram_chats DROP COLUMN IF EXISTS is_active")
