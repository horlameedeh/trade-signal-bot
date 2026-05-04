"""add terminal sessions

Revision ID: 89f12e0ba78a
Revises: e5298330e129
Create Date: 2026-05-04 23:15:42.820322

"""
from __future__ import annotations

from alembic import op
import sqlalchemy as sa


revision: str = "89f12e0ba78a"
down_revision: str | None = "e5298330e129"
branch_labels: str | None = None
depends_on: str | None = None


def upgrade() -> None:
    op.create_table(
        "terminal_sessions",
        sa.Column(
            "session_id",
            sa.UUID(),
            nullable=False,
            server_default=sa.text("gen_random_uuid()"),
        ),
        sa.Column("terminal_name", sa.Text(), nullable=False),
        sa.Column("status", sa.Text(), nullable=False, server_default=sa.text("'active'")),
        sa.Column("started_at", sa.TIMESTAMP(timezone=True), nullable=False, server_default=sa.text("now()")),
        sa.Column("ended_at", sa.TIMESTAMP(timezone=True), nullable=True),
        sa.Column("meta", sa.JSON(), nullable=False, server_default=sa.text("'{}'::jsonb")),
        sa.PrimaryKeyConstraint("session_id"),
    )
    op.create_index(
        "idx_terminal_sessions_status",
        "terminal_sessions",
        ["status"],
        unique=False,
    )
    op.create_index(
        "uq_terminal_sessions_terminal_name_started_at",
        "terminal_sessions",
        ["terminal_name", "started_at"],
        unique=True,
    )


def downgrade() -> None:
    op.execute("DROP TABLE IF EXISTS terminal_sessions CASCADE")
