"""add terminal_sessions user_id

Revision ID: 996c8a6a1706
Revises: 89f12e0ba78a
Create Date: 2026-05-05 19:26:25.276020

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '996c8a6a1706'
down_revision: Union[str, Sequence[str], None] = '89f12e0ba78a'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    op.execute(
        """
        ALTER TABLE terminal_sessions
        ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES users(user_id) ON DELETE RESTRICT
        """
    )

    op.execute(
        """
        UPDATE terminal_sessions ts
        SET user_id = ba.user_id
        FROM broker_accounts ba
        WHERE ba.account_id = ts.broker_account_id
          AND ts.user_id IS NULL
          AND ba.user_id IS NOT NULL
        """
    )

    op.execute(
        """
        DO $$ BEGIN
            IF NOT EXISTS (
                SELECT 1 FROM pg_indexes
                WHERE tablename = 'terminal_sessions' AND indexname = 'idx_terminal_sessions_user_id'
            ) THEN
                CREATE INDEX idx_terminal_sessions_user_id ON terminal_sessions(user_id);
            END IF;
        END $$
        """
    )


def downgrade() -> None:
    """Downgrade schema."""
    op.execute("DROP INDEX IF EXISTS idx_terminal_sessions_user_id")
    op.execute("ALTER TABLE terminal_sessions DROP COLUMN IF EXISTS user_id")
