"""add terminal_sessions user_id

Revision ID: 46af22d118fa
Revises: 6b7f5f1f8abc
Create Date: 2026-05-05 19:46:26.464356

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '46af22d118fa'
down_revision: Union[str, Sequence[str], None] = '6b7f5f1f8abc'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    pass


def downgrade() -> None:
    """Downgrade schema."""
    pass
