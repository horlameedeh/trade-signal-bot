"""merge provider fallback and identity slot heads

Revision ID: b93ec837f5fb
Revises: 28c3_provider_route_fallback, f2d4c3b9a1e8
Create Date: 2026-05-14 00:00:00.000000

"""
from typing import Sequence, Union


# revision identifiers, used by Alembic.
revision: str = "b93ec837f5fb"
down_revision: Union[str, Sequence[str], None] = (
    "28c3_provider_route_fallback",
    "f2d4c3b9a1e8",
)
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    pass


def downgrade() -> None:
    pass