"""milestone5 trade families and management metadata

Revision ID: 3051ce82147d
Revises: 2b3680d79745
"""

from __future__ import annotations

from alembic import op
import sqlalchemy as sa


revision: str = "3051ce82147d"
down_revision: str | None = "2b3680d79745"
branch_labels: str | None = None
depends_on: str | None = None


def upgrade() -> None:
    op.create_table(
        "trade_families",
        sa.Column("family_id", sa.UUID(), nullable=False, server_default=sa.text("gen_random_uuid()")),
        sa.Column("intent_id", sa.UUID(), nullable=False),
        sa.Column("plan_id", sa.UUID(), nullable=True),
        sa.Column("provider", sa.Text(), nullable=False),
        sa.Column("account_id", sa.UUID(), nullable=True),
        sa.Column("chat_id", sa.BigInteger(), nullable=True),
        sa.Column("source_msg_pk", sa.UUID(), nullable=False),
        sa.Column("symbol_canonical", sa.Text(), nullable=True),
        sa.Column("side", sa.Text(), nullable=True),
        sa.Column("entry_price", sa.Numeric(18, 10), nullable=True),
        sa.Column("sl_price", sa.Numeric(18, 10), nullable=True),
        sa.Column("tp_count", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("state", sa.Text(), nullable=False, server_default="OPEN"),
        sa.Column("is_stub", sa.Boolean(), nullable=False, server_default=sa.text("false")),
        sa.Column("management_rules", sa.JSON(), nullable=False, server_default=sa.text("'{}'::jsonb")),
        sa.Column("meta", sa.JSON(), nullable=False, server_default=sa.text("'{}'::jsonb")),
        sa.Column("created_at", sa.TIMESTAMP(timezone=True), nullable=False, server_default=sa.text("now()")),
        sa.Column("updated_at", sa.TIMESTAMP(timezone=True), nullable=False, server_default=sa.text("now()")),
        sa.PrimaryKeyConstraint("family_id"),
    )

    op.create_index("uq_trade_families_source_msg_pk", "trade_families", ["source_msg_pk"], unique=True)
    op.create_index("idx_trade_families_provider_symbol_state", "trade_families", ["provider", "symbol_canonical", "state"], unique=False)

    op.create_foreign_key(
        "trade_families_intent_id_fkey",
        "trade_families",
        "trade_intents",
        ["intent_id"],
        ["intent_id"],
        ondelete="CASCADE",
    )

    op.create_foreign_key(
        "trade_families_plan_id_fkey",
        "trade_families",
        "trade_plans",
        ["plan_id"],
        ["plan_id"],
        ondelete="SET NULL",
    )

    # Optional columns on trade_legs to link legs back to family and preserve target ordering
    bind = op.get_bind()
    insp = sa.inspect(bind)
    cols = {c["name"] for c in insp.get_columns("trade_legs")}

    if "family_id" not in cols:
        op.add_column("trade_legs", sa.Column("family_id", sa.UUID(), nullable=True))
        op.create_foreign_key(
            "trade_legs_family_id_fkey",
            "trade_legs",
            "trade_families",
            ["family_id"],
            ["family_id"],
            ondelete="CASCADE",
        )

    if "leg_index" not in cols:
        op.add_column("trade_legs", sa.Column("leg_index", sa.Integer(), nullable=True))

    if "tp_price" not in cols:
        op.add_column("trade_legs", sa.Column("tp_price", sa.Numeric(18, 10), nullable=True))

    if "sl_price" not in cols:
        op.add_column("trade_legs", sa.Column("sl_price", sa.Numeric(18, 10), nullable=True))

    if "entry_price" not in cols:
        op.add_column("trade_legs", sa.Column("entry_price", sa.Numeric(18, 10), nullable=True))

    if "state" not in cols:
        op.add_column("trade_legs", sa.Column("state", sa.Text(), nullable=False, server_default="OPEN"))


def downgrade() -> None:
    bind = op.get_bind()
    insp = sa.inspect(bind)
    cols = {c["name"] for c in insp.get_columns("trade_legs")}

    for fk_name in ["trade_legs_family_id_fkey"]:
        try:
            op.drop_constraint(fk_name, "trade_legs", type_="foreignkey")
        except Exception:
            pass

    for col in ["family_id", "leg_index", "tp_price", "sl_price", "entry_price", "state"]:
        if col in cols:
            op.drop_column("trade_legs", col)

    op.drop_index("idx_trade_families_provider_symbol_state", table_name="trade_families")
    op.drop_index("uq_trade_families_source_msg_pk", table_name="trade_families")
    op.drop_table("trade_families")
