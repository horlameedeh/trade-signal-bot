"""provider_account_routes allow history and enforce one active

Revision ID: 8d46443bb1a4
Revises: da00f7f68e77
Create Date: 2026-02-23 22:48:46.119225

"""
from __future__ import annotations

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "8d46443bb1a4"
down_revision: str | None = "da00f7f68e77"
branch_labels: str | None = None
depends_on: str | None = None


def upgrade() -> None:
    # 1) Drop the overly-strict unique constraint: one row total per provider (prevents history)
    #    Existing name confirmed from \d provider_account_routes:
    #      provider_account_routes_provider_code_key UNIQUE(provider_code)
    op.drop_constraint(
        "provider_account_routes_provider_code_key",
        "provider_account_routes",
        type_="unique",
    )

    # 2) Safety check: ensure we don't already have >1 active row per provider
    #    (should be true in your current data model, but we enforce before adding index)
    op.execute(
        sa.text(
            """
            DO $$
            BEGIN
              IF EXISTS (
                SELECT 1
                FROM provider_account_routes
                WHERE is_active = true
                GROUP BY provider_code
                HAVING COUNT(*) > 1
              ) THEN
                RAISE EXCEPTION 'Cannot add one-active-per-provider constraint: multiple active routes exist.';
              END IF;
            END $$;
            """
        )
    )

    # 3) Add partial unique index: only one active route per provider
    #    NOTE: cannot use CONCURRENTLY inside Alembic's transaction; OK for this small table.
    op.execute(
        sa.text(
            """
            CREATE UNIQUE INDEX IF NOT EXISTS uq_provider_account_routes_one_active
            ON provider_account_routes (provider_code)
            WHERE is_active = true;
            """
        )
    )


def downgrade() -> None:
    # 1) Drop the partial unique index
    op.execute(sa.text("DROP INDEX IF EXISTS uq_provider_account_routes_one_active;"))

    # 2) Re-create the old UNIQUE(provider_code) constraint
    op.create_unique_constraint(
        "provider_account_routes_provider_code_key",
        "provider_account_routes",
        ["provider_code"],
    )
