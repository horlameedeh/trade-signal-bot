"""execution tickets and node registry

Revision ID: f2821d8a6363
Revises: 10f86e972f71
"""

from __future__ import annotations

from alembic import op
import sqlalchemy as sa


revision: str = "f2821d8a6363"
down_revision: str | None = "10f86e972f71"
branch_labels: str | None = None
depends_on: str | None = None


def upgrade() -> None:
    op.create_table(
        "execution_nodes",
        sa.Column("node_id", sa.UUID(), nullable=False, server_default=sa.text("gen_random_uuid()")),
        sa.Column("name", sa.Text(), nullable=False),
        sa.Column("broker", sa.Text(), nullable=False),
        sa.Column("platform", sa.Text(), nullable=False),
        sa.Column("base_url", sa.Text(), nullable=True),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.text("true")),
        sa.Column("meta", sa.JSON(), nullable=False, server_default=sa.text("'{}'::jsonb")),
        sa.Column("created_at", sa.TIMESTAMP(timezone=True), nullable=False, server_default=sa.text("now()")),
        sa.PrimaryKeyConstraint("node_id"),
    )
    op.create_index("uq_execution_nodes_broker_platform_name", "execution_nodes", ["broker", "platform", "name"], unique=True)

    op.create_table(
        "execution_tickets",
        sa.Column("ticket_id", sa.UUID(), nullable=False, server_default=sa.text("gen_random_uuid()")),
        sa.Column("leg_id", sa.UUID(), nullable=False),
        sa.Column("family_id", sa.UUID(), nullable=False),
        sa.Column("node_id", sa.UUID(), nullable=True),
        sa.Column("broker", sa.Text(), nullable=False),
        sa.Column("platform", sa.Text(), nullable=False),
        sa.Column("broker_symbol", sa.Text(), nullable=False),
        sa.Column("broker_ticket", sa.Text(), nullable=False),
        sa.Column("side", sa.Text(), nullable=False),
        sa.Column("order_type", sa.Text(), nullable=True),
        sa.Column("requested_entry", sa.Numeric(18, 10), nullable=True),
        sa.Column("actual_fill_price", sa.Numeric(18, 10), nullable=True),
        sa.Column("sl_price", sa.Numeric(18, 10), nullable=True),
        sa.Column("tp_price", sa.Numeric(18, 10), nullable=True),
        sa.Column("lots", sa.Numeric(18, 4), nullable=True),
        sa.Column("status", sa.Text(), nullable=False, server_default="open"),
        sa.Column("raw_response", sa.JSON(), nullable=False, server_default=sa.text("'{}'::jsonb")),
        sa.Column("created_at", sa.TIMESTAMP(timezone=True), nullable=False, server_default=sa.text("now()")),
        sa.Column("updated_at", sa.TIMESTAMP(timezone=True), nullable=False, server_default=sa.text("now()")),
        sa.PrimaryKeyConstraint("ticket_id"),
    )

    op.create_index("uq_execution_tickets_leg", "execution_tickets", ["leg_id"], unique=True)
    op.create_index("uq_execution_tickets_broker_ticket", "execution_tickets", ["broker", "platform", "broker_ticket"], unique=True)
    op.create_index("idx_execution_tickets_family", "execution_tickets", ["family_id"], unique=False)

    op.create_foreign_key(
        "execution_tickets_leg_id_fkey",
        "execution_tickets",
        "trade_legs",
        ["leg_id"],
        ["leg_id"],
        ondelete="CASCADE",
    )
    op.create_foreign_key(
        "execution_tickets_family_id_fkey",
        "execution_tickets",
        "trade_families",
        ["family_id"],
        ["family_id"],
        ondelete="CASCADE",
    )
    op.create_foreign_key(
        "execution_tickets_node_id_fkey",
        "execution_tickets",
        "execution_nodes",
        ["node_id"],
        ["node_id"],
        ondelete="SET NULL",
    )


def downgrade() -> None:
    op.drop_table("execution_tickets")
    op.drop_index("uq_execution_nodes_broker_platform_name", table_name="execution_nodes")
    op.drop_table("execution_nodes")
