"""add identity slots to users

Revision ID: f2d4c3b9a1e8
Revises: 9a17d3e5b0c1
Create Date: 2026-05-10 19:25:00.000000

"""
from typing import Sequence, Union

from alembic import op


# revision identifiers, used by Alembic.
revision: str = "f2d4c3b9a1e8"
down_revision: Union[str, Sequence[str], None] = "46af22d118fa"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.execute("ALTER TABLE users ALTER COLUMN telegram_user_id DROP NOT NULL")
    op.execute(
        """
        ALTER TABLE users
        ADD COLUMN IF NOT EXISTS identity_slot TEXT
        """
    )
    op.execute(
        """
        DO $$ BEGIN
            IF NOT EXISTS (
                SELECT 1
                FROM information_schema.table_constraints
                WHERE table_schema = 'public'
                  AND table_name = 'users'
                  AND constraint_type = 'UNIQUE'
                  AND constraint_name = 'users_identity_slot_key'
            ) THEN
                ALTER TABLE users
                ADD CONSTRAINT users_identity_slot_key UNIQUE (identity_slot);
            END IF;
        END $$
        """
    )


def downgrade() -> None:
    op.execute(
        """
        DELETE FROM users
        WHERE telegram_user_id IS NULL
          AND identity_slot IS NOT NULL
        """
    )
    op.execute(
        """
        DO $$ BEGIN
            IF EXISTS (
                SELECT 1
                FROM information_schema.table_constraints
                WHERE table_schema = 'public'
                  AND table_name = 'users'
                  AND constraint_name = 'users_identity_slot_key'
            ) THEN
                ALTER TABLE users DROP CONSTRAINT users_identity_slot_key;
            END IF;
        END $$
        """
    )
    op.execute("ALTER TABLE users DROP COLUMN IF EXISTS identity_slot")
    op.execute(
        """
        ALTER TABLE users
        ALTER COLUMN telegram_user_id SET NOT NULL
        """
    )