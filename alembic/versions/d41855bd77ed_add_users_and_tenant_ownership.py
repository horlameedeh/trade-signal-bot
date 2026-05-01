"""add users and tenant ownership

Revision ID: d41855bd77ed
Revises: 712547960cbf
Create Date: 2026-05-01 20:19:41.448850

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


# revision identifiers, used by Alembic.
revision: str = 'd41855bd77ed'
down_revision: Union[str, Sequence[str], None] = '712547960cbf'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # users table may already exist (created outside migrations)
    op.execute(
        """
        CREATE TABLE IF NOT EXISTS users (
            user_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            telegram_user_id BIGINT UNIQUE NOT NULL,
            display_name TEXT,
            role TEXT NOT NULL DEFAULT 'user',
            is_active BOOLEAN NOT NULL DEFAULT true,
            created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
            updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
        )
        """
    )

    # Ensure legacy externally-created users tables are brought up to expected shape.
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

    op.create_table(
        "user_control_chats",
        sa.Column("control_chat_id", postgresql.UUID(as_uuid=True), primary_key=True, server_default=sa.text("gen_random_uuid()")),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("users.user_id", ondelete="CASCADE"), nullable=False),
        sa.Column("telegram_chat_id", sa.BigInteger(), unique=True, nullable=False),
        sa.Column("label", sa.Text(), nullable=True),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.text("true")),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.text("now()")),
        if_not_exists=True,
    )

    # broker_accounts.user_id may already exist
    op.execute(
        """
        ALTER TABLE broker_accounts
        ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES users(user_id) ON DELETE RESTRICT
        """
    )

    # broker_credentials.user_id is new
    op.execute(
        """
        ALTER TABLE broker_credentials
        ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES users(user_id) ON DELETE CASCADE
        """
    )

    op.execute(
        """
        DO $$ BEGIN
            IF NOT EXISTS (
                SELECT 1 FROM pg_indexes
                WHERE tablename = 'users' AND indexname = 'idx_users_telegram_user_id'
            ) THEN
                CREATE INDEX idx_users_telegram_user_id ON users(telegram_user_id);
            END IF;
        END $$
        """
    )
    op.execute(
        """
        DO $$ BEGIN
            IF NOT EXISTS (
                SELECT 1 FROM pg_indexes
                WHERE tablename = 'broker_accounts' AND indexname = 'idx_broker_accounts_user_id'
            ) THEN
                CREATE INDEX idx_broker_accounts_user_id ON broker_accounts(user_id);
            END IF;
        END $$
        """
    )
    op.execute(
        """
        DO $$ BEGIN
            IF NOT EXISTS (
                SELECT 1 FROM pg_indexes
                WHERE tablename = 'broker_credentials' AND indexname = 'idx_broker_credentials_user_id'
            ) THEN
                CREATE INDEX idx_broker_credentials_user_id ON broker_credentials(user_id);
            END IF;
        END $$
        """
    )


def downgrade() -> None:
    op.execute("DROP INDEX IF EXISTS idx_broker_credentials_user_id")
    op.execute("DROP INDEX IF EXISTS idx_broker_accounts_user_id")
    op.execute("DROP INDEX IF EXISTS idx_users_telegram_user_id")

    op.execute(
        """
        DO $$ BEGIN
            IF EXISTS (
                SELECT 1 FROM information_schema.table_constraints
                WHERE constraint_name = 'fk_broker_credentials_user_id'
            ) THEN
                ALTER TABLE broker_credentials DROP CONSTRAINT fk_broker_credentials_user_id;
            END IF;
        END $$
        """
    )
    op.execute("ALTER TABLE broker_credentials DROP COLUMN IF EXISTS user_id")

    op.execute(
        """
        DO $$ BEGIN
            IF EXISTS (
                SELECT 1 FROM information_schema.table_constraints
                WHERE constraint_name = 'fk_broker_accounts_user_id'
            ) THEN
                ALTER TABLE broker_accounts DROP CONSTRAINT fk_broker_accounts_user_id;
            END IF;
        END $$
        """
    )
    op.execute("ALTER TABLE broker_accounts DROP COLUMN IF EXISTS user_id")

    op.drop_table("user_control_chats")
    op.drop_table("users")



