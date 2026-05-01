"""replace_broker_credentials_with_encrypted_schema

Revision ID: 3b1270969208
Revises: a1b2c3d4e5f6
Create Date: 2026-05-01 13:11:28.160345

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '3b1270969208'
down_revision: Union[str, Sequence[str], None] = 'a1b2c3d4e5f6'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Drop old broker_credentials table and create redesigned encrypted schema."""
    op.execute("DROP TABLE IF EXISTS broker_credentials CASCADE")
    op.execute(
        """
        CREATE TABLE broker_credentials (
          credential_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
          account_label text UNIQUE NOT NULL,
          broker text,
          platform text,
          login_enc text,
          password_enc text,
          server_enc text,
          created_at timestamptz NOT NULL DEFAULT now(),
          updated_at timestamptz NOT NULL DEFAULT now()
        )
        """
    )


def downgrade() -> None:
    """Restore original broker_credentials table."""
    op.execute("DROP TABLE IF EXISTS broker_credentials CASCADE")
    op.execute(
        """
        CREATE TABLE broker_credentials (
          cred_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
          account_id uuid NOT NULL REFERENCES broker_accounts(account_id) ON DELETE CASCADE,
          login text,
          server text,
          password_cipher bytea,
          password_nonce bytea,
          kek_id text,
          created_at timestamptz NOT NULL DEFAULT now(),
          updated_at timestamptz NOT NULL DEFAULT now(),
          UNIQUE(account_id)
        )
        """
    )
