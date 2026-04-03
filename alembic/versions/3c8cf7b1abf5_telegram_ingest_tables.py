"""telegram ingest tables

Revision ID: 3c8cf7b1abf5
Revises: 8da18ba68ca6
Create Date: 2026-02-21 19:16:52.437396

"""

from alembic import op

# revision identifiers, used by Alembic.
revision = "3c8cf7b1abf5"
down_revision = "8da18ba68ca6"
branch_labels = None
depends_on = None


def upgrade() -> None:
    # NOTE: telegram_chats and telegram_messages are created in
    # 8da18ba68ca6_init_schema.py. This revision is intentionally a no-op to
    # avoid attempting to create tables that already exist.
    pass


def downgrade() -> None:
    # Intentionally no-op; tables are owned/dropped by the init schema revision.
    pass
