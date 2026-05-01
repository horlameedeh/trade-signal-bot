"""alter_trade_families_meta_to_jsonb

Revision ID: 712547960cbf
Revises: 3b1270969208
Create Date: 2026-05-01 19:35:32.267602

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '712547960cbf'
down_revision: Union[str, Sequence[str], None] = '3b1270969208'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.execute(
        "ALTER TABLE trade_families ALTER COLUMN meta TYPE jsonb USING meta::jsonb"
    )


def downgrade() -> None:
    op.execute(
        "ALTER TABLE trade_families ALTER COLUMN meta TYPE json USING meta::json"
    )
