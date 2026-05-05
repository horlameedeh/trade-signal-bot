from __future__ import annotations

import subprocess
import sys
import uuid
from pathlib import Path

from sqlalchemy import text

from app.db.session import SessionLocal

ROOT = Path(__file__).resolve().parents[1]


def _cleanup(account_id: str, telegram_user_id: int) -> None:
    with SessionLocal() as db:
        db.execute(
            text("DELETE FROM terminal_sessions WHERE broker_account_id = CAST(:account_id AS uuid)"),
            {"account_id": account_id},
        )
        db.execute(
            text("DELETE FROM broker_accounts WHERE account_id = CAST(:account_id AS uuid)"),
            {"account_id": account_id},
        )
        db.execute(
            text("DELETE FROM users WHERE telegram_user_id = :telegram_user_id"),
            {"telegram_user_id": telegram_user_id},
        )
        db.commit()


def test_backfill_execution_account_owners_updates_account_and_terminal() -> None:
    account_id = str(uuid.uuid4())
    terminal_name = f"phase7c-terminal-{uuid.uuid4()}"
    telegram_user_id = 970001

    _cleanup(account_id, telegram_user_id)

    try:
        with SessionLocal() as db:
            db.execute(
                text(
                    """
                    INSERT INTO broker_accounts (
                      account_id, broker, platform, kind, label,
                      base_currency, equity_start, equity_current,
                      allowed_providers, is_active, user_id
                    )
                    VALUES (
                      CAST(:account_id AS uuid),
                      CAST('ftmo' AS broker_code),
                                            CAST('mt4' AS platform_code),
                      CAST('personal_live' AS account_kind),
                      'FTMO - Execution',
                      'USD',
                      10000,
                      10000,
                      ARRAY[]::provider_code[],
                      true,
                      NULL
                    )
                    """
                ),
                {"account_id": account_id},
            )
            db.execute(
                text(
                    """
                    INSERT INTO terminal_sessions (
                      broker_account_id, user_id, terminal_name, terminal_path, data_dir,
                      port, status, last_heartbeat, meta
                    )
                    VALUES (
                      CAST(:account_id AS uuid),
                      NULL,
                      :terminal_name,
                      'C:\\FTMO\\terminal64.exe',
                      'C:\\FTMO',
                      9104,
                      'running',
                      now(),
                      '{}'::jsonb
                    )
                    """
                ),
                {"account_id": account_id, "terminal_name": terminal_name},
            )
            db.commit()

        result = subprocess.run(
            [
                sys.executable,
                str(ROOT / "scripts" / "backfill_execution_account_owners.py"),
                "--brokers",
                "ftmo",
                "--platform",
                "mt4",
                "--default-telegram-user-id",
                str(telegram_user_id),
                "--default-display-name",
                "FTMO Owner",
            ],
            cwd=ROOT,
            check=True,
            capture_output=True,
            text=True,
        )
        assert "updated_accounts" in result.stdout

        with SessionLocal() as db:
            row = db.execute(
                text(
                    """
                    SELECT
                      ba.user_id::text AS broker_user_id,
                      ts.user_id::text AS terminal_user_id
                    FROM broker_accounts ba
                    JOIN terminal_sessions ts
                      ON ts.broker_account_id = ba.account_id
                    WHERE ba.account_id = CAST(:account_id AS uuid)
                    LIMIT 1
                    """
                ),
                {"account_id": account_id},
            ).mappings().first()

        assert row is not None
        assert row["broker_user_id"]
        assert row["broker_user_id"] == row["terminal_user_id"]
    finally:
        _cleanup(account_id, telegram_user_id)