"""backfill users schema columns

Revision ID: 9a17d3e5b0c1
Revises: d41855bd77ed
Create Date: 2026-05-01 20:55:00.000000

"""
from typing import Sequence, Union

from alembic import op


# revision identifiers, used by Alembic.
revision: str = "9a17d3e5b0c1"
down_revision: Union[str, Sequence[str], None] = "d41855bd77ed"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.execute(
        """
        ALTER TABLE users
        ADD COLUMN IF NOT EXISTS role TEXT NOT NULL DEFAULT 'user'
        """
    )
    op.execute(
        """
        ALTER TABLE users
        ADD COLUMN IF NOT EXISTS is_active BOOLEAN NOT NULL DEFAULT true
        """
    )
    op.execute(
        """
        ALTER TABLE users
        ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT now()
        """
    )
    op.execute(
        """
        ALTER TABLE users
        ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
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
                  AND constraint_name = 'users_telegram_user_id_key'
            ) THEN
                ALTER TABLE users
                ADD CONSTRAINT users_telegram_user_id_key UNIQUE (telegram_user_id);
            END IF;
        END $$
        """
    )


def downgrade() -> None:
    op.execute(
        """
        DO $$ BEGIN
            IF EXISTS (
                SELECT 1
                FROM information_schema.table_constraints
                WHERE table_schema = 'public'
                  AND table_name = 'users'
                  AND constraint_name = 'users_telegram_user_id_key'
            ) THEN
                ALTER TABLE users DROP CONSTRAINT users_telegram_user_id_key;
            END IF;
        END $$
        """
    )
    op.execute("ALTER TABLE users DROP COLUMN IF EXISTS updated_at")
    op.execute("ALTER TABLE users DROP COLUMN IF EXISTS created_at")
    op.execute("ALTER TABLE users DROP COLUMN IF EXISTS is_active")
    op.execute("ALTER TABLE users DROP COLUMN IF EXISTS role")
