"""mock execution records for dry run

Revision ID: 10f86e972f71
Revises: 460e5ad4fa56
"""

from __future__ import annotations

from alembic import op
import sqlalchemy as sa


revision: str = "10f86e972f71"
down_revision: str | None = "460e5ad4fa56"
branch_labels: str | None = None
depends_on: str | None = None


def upgrade() -> None:
    op.create_table(
        "mock_executions",
        sa.Column("execution_id", sa.UUID(), nullable=False, server_default=sa.text("gen_random_uuid()")),
        sa.Column("family_id", sa.UUID(), nullable=False),
        sa.Column("leg_id", sa.UUID(), nullable=False),
        sa.Column("source_msg_pk", sa.UUID(), nullable=False),
        sa.Column("broker", sa.Text(), nullable=True),
        sa.Column("platform", sa.Text(), nullable=True),
        sa.Column("broker_symbol", sa.Text(), nullable=True),
        sa.Column("order_type", sa.Text(), nullable=True),
        sa.Column("side", sa.Text(), nullable=True),
        sa.Column("requested_entry", sa.Numeric(18, 10), nullable=True),
        sa.Column("tp_price", sa.Numeric(18, 10), nullable=True),
        sa.Column("sl_price", sa.Numeric(18, 10), nullable=True),
        sa.Column("lots", sa.Numeric(18, 4), nullable=True),
        sa.Column("placement_delay_ms", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("status", sa.Text(), nullable=False, server_default="planned"),
        sa.Column("meta", sa.JSON(), nullable=False, server_default=sa.text("'{}'::jsonb")),
        sa.Column("created_at", sa.TIMESTAMP(timezone=True), nullable=False, server_default=sa.text("now()")),
        sa.PrimaryKeyConstraint("execution_id"),
    )

    op.create_index("uq_mock_executions_leg", "mock_executions", ["leg_id"], unique=True)
    op.create_index("idx_mock_executions_family", "mock_executions", ["family_id"], unique=False)
    op.create_index("idx_mock_executions_source_msg_pk", "mock_executions", ["source_msg_pk"], unique=False)

    op.create_foreign_key(
        "mock_executions_family_id_fkey",
        "mock_executions",
        "trade_families",
        ["family_id"],
        ["family_id"],
        ondelete="CASCADE",
    )
    op.create_foreign_key(
        "mock_executions_leg_id_fkey",
        "mock_executions",
        "trade_legs",
        ["leg_id"],
        ["leg_id"],
        ondelete="CASCADE",
    )


def downgrade() -> None:
    op.drop_index("idx_mock_executions_source_msg_pk", table_name="mock_executions")
    op.drop_index("idx_mock_executions_family", table_name="mock_executions")
    op.drop_index("uq_mock_executions_leg", table_name="mock_executions")
    op.drop_table("mock_executions")
