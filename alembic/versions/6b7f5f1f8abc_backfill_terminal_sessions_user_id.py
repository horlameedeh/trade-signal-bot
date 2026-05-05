"""backfill terminal_sessions user_id

Revision ID: 6b7f5f1f8abc
Revises: 996c8a6a1706
Create Date: 2026-05-05 20:10:00.000000

"""
from typing import Sequence, Union

from alembic import op


# revision identifiers, used by Alembic.
revision: str = "6b7f5f1f8abc"
down_revision: Union[str, Sequence[str], None] = "996c8a6a1706"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
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
    op.execute("DROP INDEX IF EXISTS idx_terminal_sessions_user_id")
    op.execute("ALTER TABLE terminal_sessions DROP COLUMN IF EXISTS user_id")