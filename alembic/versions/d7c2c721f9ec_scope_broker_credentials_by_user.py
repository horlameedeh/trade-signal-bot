"""scope broker credentials by user

Revision ID: d7c2c721f9ec
Revises: 9a17d3e5b0c1
Create Date: 2026-05-01 20:40:51.931614

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'd7c2c721f9ec'
down_revision: Union[str, Sequence[str], None] = '9a17d3e5b0c1'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.drop_constraint("broker_credentials_account_label_key", "broker_credentials", type_="unique")
    op.create_unique_constraint(
        "uq_broker_credentials_user_label",
        "broker_credentials",
        ["user_id", "account_label"],
    )


def downgrade() -> None:
    op.drop_constraint("uq_broker_credentials_user_label", "broker_credentials", type_="unique")
    op.create_unique_constraint(
        "broker_credentials_account_label_key",
        "broker_credentials",
        ["account_label"],
    )
