"""rename vtmarkets broker to bullwaves

Revision ID: 9166a29866ec
Revises: e0993c509388
Create Date: 2026-05-03 22:13:18.797876

"""

from alembic import op


# revision identifiers, used by Alembic.
revision = "9166a29866ec"
down_revision = "e0993c509388"
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Postgres requires committing enum value additions before using them.
    with op.get_context().autocommit_block():
        op.execute("ALTER TYPE broker_code ADD VALUE IF NOT EXISTS 'bullwaves'")

    op.execute(
        """
        UPDATE broker_accounts
        SET broker = 'bullwaves'
        WHERE broker::text = 'vtmarkets'
        """
    )

    op.execute(
        """
        UPDATE execution_nodes
        SET broker = 'bullwaves'
        WHERE broker::text = 'vtmarkets'
        """
    )

    op.execute(
        """
        UPDATE execution_tickets
        SET broker = 'bullwaves'
        WHERE broker::text = 'vtmarkets'
        """
    )


def downgrade() -> None:
    op.execute(
        """
        UPDATE broker_accounts
        SET broker = 'vtmarkets'
        WHERE broker::text = 'bullwaves'
        """
    )

    op.execute(
        """
        UPDATE execution_nodes
        SET broker = 'vtmarkets'
        WHERE broker::text = 'bullwaves'
        """
    )

    op.execute(
        """
        UPDATE execution_tickets
        SET broker = 'vtmarkets'
        WHERE broker::text = 'bullwaves'
        """
    )

    op.execute(
        """
        DO $$
        DECLARE
            rec RECORD;
        BEGIN
            IF NOT EXISTS (
                SELECT 1
                FROM pg_enum e
                JOIN pg_type t ON t.oid = e.enumtypid
                WHERE t.typname = 'broker_code' AND e.enumlabel = 'bullwaves'
            ) THEN
                RETURN;
            END IF;

            ALTER TYPE broker_code RENAME TO broker_code_old;

            CREATE TYPE broker_code AS ENUM (
                'vantage',
                'ftmo',
                'traderscale',
                'fundednext',
                'startrader',
                'vtmarkets'
            );

            FOR rec IN
                SELECT n.nspname AS schema_name,
                       c.relname AS table_name,
                       a.attname AS column_name
                FROM pg_attribute a
                JOIN pg_class c ON c.oid = a.attrelid
                JOIN pg_namespace n ON n.oid = c.relnamespace
                JOIN pg_type t ON t.oid = a.atttypid
                WHERE t.typname = 'broker_code_old'
                  AND a.attnum > 0
                  AND NOT a.attisdropped
                  AND c.relkind IN ('r', 'p')
            LOOP
                EXECUTE format(
                    'ALTER TABLE %I.%I ALTER COLUMN %I TYPE broker_code USING %I::text::broker_code',
                    rec.schema_name,
                    rec.table_name,
                    rec.column_name,
                    rec.column_name
                );
            END LOOP;

            DROP TYPE broker_code_old;
        END$$;
        """
    )
