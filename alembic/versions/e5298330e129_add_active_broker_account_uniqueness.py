"""add active broker account uniqueness

Revision ID: e5298330e129
Revises: 9166a29866ec
Create Date: 2026-05-04 20:03:59.680422

"""
from alembic import op

revision = "e5298330e129"
down_revision = "9166a29866ec"
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Deactivate duplicate active accounts per (broker, platform), keeping
    # only the most recently updated/created one before enforcing uniqueness.
    op.execute(
        """
        UPDATE broker_accounts
        SET is_active = false
        WHERE account_id IN (
            SELECT account_id
            FROM (
                SELECT account_id,
                       ROW_NUMBER() OVER (
                           PARTITION BY broker, platform
                           ORDER BY updated_at DESC NULLS LAST,
                                    created_at DESC NULLS LAST
                       ) AS rn
                FROM broker_accounts
                WHERE is_active = true
            ) ranked
            WHERE rn > 1
        );
        """
    )
    op.execute(
        """
        CREATE UNIQUE INDEX IF NOT EXISTS uniq_active_execution_account
        ON broker_accounts (broker, platform)
        WHERE is_active = true;
        """
    )


def downgrade() -> None:
    op.execute("DROP INDEX IF EXISTS uniq_active_execution_account;")
