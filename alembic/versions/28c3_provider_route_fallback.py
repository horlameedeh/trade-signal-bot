"""Milestone 28C.3 provider route fallback support

Revision ID: 28c3_provider_route_fallback
Revises: 996c8a6a1706
Create Date: 2026-05-14

"""
from alembic import op
import sqlalchemy as sa


revision = "28c3_provider_route_fallback"
down_revision = "996c8a6a1706"
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Add explicit fallback routing fields.
    op.execute("""
        ALTER TABLE provider_account_routes
        ADD COLUMN IF NOT EXISTS route_priority integer NOT NULL DEFAULT 100;
    """)

    op.execute("""
        ALTER TABLE provider_account_routes
        ADD COLUMN IF NOT EXISTS route_role text NOT NULL DEFAULT 'primary';
    """)

    # The old rule allowed only one active route per provider.
    # It may be implemented as either a constraint or an index depending on migration history.
    op.execute("""
        ALTER TABLE provider_account_routes
        DROP CONSTRAINT IF EXISTS uq_provider_account_routes_one_active;
    """)

    op.execute("""
        DROP INDEX IF EXISTS uq_provider_account_routes_one_active;
    """)

    # Ensure one provider/account pair is represented once.
    op.execute("""
        CREATE UNIQUE INDEX IF NOT EXISTS uq_provider_account_routes_provider_account
        ON provider_account_routes (provider_code, broker_account_id);
    """)

    # Ensure active routes for a provider have deterministic unique priorities.
    op.execute("""
        CREATE UNIQUE INDEX IF NOT EXISTS uq_provider_account_routes_active_priority
        ON provider_account_routes (provider_code, route_priority)
        WHERE is_active = TRUE;
    """)

    op.execute("""
        CREATE INDEX IF NOT EXISTS idx_provider_account_routes_active_order
        ON provider_account_routes (provider_code, is_active, route_priority);
    """)


def downgrade() -> None:
    op.execute("""
        DROP INDEX IF EXISTS idx_provider_account_routes_active_order;
    """)

    op.execute("""
        DROP INDEX IF EXISTS uq_provider_account_routes_active_priority;
    """)

    op.execute("""
        DROP INDEX IF EXISTS uq_provider_account_routes_provider_account;
    """)

    # Recreate old single-active-provider rule.
    op.execute("""
        CREATE UNIQUE INDEX IF NOT EXISTS uq_provider_account_routes_one_active
        ON provider_account_routes (provider_code)
        WHERE is_active = TRUE;
    """)

    op.execute("""
        ALTER TABLE provider_account_routes
        DROP COLUMN IF EXISTS route_role;
    """)

    op.execute("""
        ALTER TABLE provider_account_routes
        DROP COLUMN IF EXISTS route_priority;
    """)
