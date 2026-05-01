from __future__ import annotations

import os
from dataclasses import dataclass

from cryptography.fernet import Fernet
from sqlalchemy import text

from app.db.session import SessionLocal


@dataclass(frozen=True)
class BrokerCredentialInput:
    account_label: str
    broker: str | None = None
    platform: str | None = None
    login: str | None = None
    password: str | None = None
    server: str | None = None


@dataclass(frozen=True)
class BrokerCredentialView:
    account_label: str
    broker: str | None
    platform: str | None
    login: str | None
    server: str | None
    has_password: bool


def _fernet() -> Fernet:
    key = os.getenv("TRADEBOT_SECRET_KEY")
    if not key:
        raise RuntimeError("TRADEBOT_SECRET_KEY is not set")
    return Fernet(key.encode())


def _encrypt(value: str | None) -> str | None:
    if value is None:
        return None
    return _fernet().encrypt(value.encode()).decode()


def _decrypt(value: str | None) -> str | None:
    if not value:
        return None
    return _fernet().decrypt(value.encode()).decode()


def ensure_credentials_table() -> None:
    with SessionLocal() as db:
        db.execute(
            text(
                """
                CREATE TABLE IF NOT EXISTS broker_credentials (
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
        )
        db.commit()


def upsert_broker_credentials(inp: BrokerCredentialInput) -> BrokerCredentialView:
    ensure_credentials_table()

    login_enc = _encrypt(inp.login) if inp.login is not None else None
    password_enc = _encrypt(inp.password) if inp.password is not None else None
    server_enc = _encrypt(inp.server) if inp.server is not None else None

    with SessionLocal() as db:
        db.execute(
            text(
                """
                INSERT INTO broker_credentials (
                  account_label, broker, platform, login_enc, password_enc, server_enc
                )
                VALUES (
                  :account_label, :broker, :platform, :login_enc, :password_enc, :server_enc
                )
                ON CONFLICT (account_label)
                DO UPDATE SET
                  broker = COALESCE(EXCLUDED.broker, broker_credentials.broker),
                  platform = COALESCE(EXCLUDED.platform, broker_credentials.platform),
                  login_enc = COALESCE(EXCLUDED.login_enc, broker_credentials.login_enc),
                  password_enc = COALESCE(EXCLUDED.password_enc, broker_credentials.password_enc),
                  server_enc = COALESCE(EXCLUDED.server_enc, broker_credentials.server_enc),
                  updated_at = now()
                """
            ),
            {
                "account_label": inp.account_label,
                "broker": inp.broker,
                "platform": inp.platform,
                "login_enc": login_enc,
                "password_enc": password_enc,
                "server_enc": server_enc,
            },
        )
        db.commit()

    return get_broker_credentials_view(inp.account_label)


def get_broker_credentials_view(account_label: str) -> BrokerCredentialView:
    ensure_credentials_table()

    with SessionLocal() as db:
        row = db.execute(
            text(
                """
                SELECT account_label, broker, platform, login_enc, password_enc, server_enc
                FROM broker_credentials
                WHERE account_label = :account_label
                LIMIT 1
                """
            ),
            {"account_label": account_label},
        ).mappings().first()

    if not row:
        raise RuntimeError(f"broker credential account not found: {account_label}")

    return BrokerCredentialView(
        account_label=row["account_label"],
        broker=row["broker"],
        platform=row["platform"],
        login=_decrypt(row["login_enc"]),
        server=_decrypt(row["server_enc"]),
        has_password=bool(row["password_enc"]),
    )


def get_broker_password(account_label: str) -> str | None:
    ensure_credentials_table()

    with SessionLocal() as db:
        enc = db.execute(
            text(
                """
                SELECT password_enc
                FROM broker_credentials
                WHERE account_label = :account_label
                LIMIT 1
                """
            ),
            {"account_label": account_label},
        ).scalar()

    return _decrypt(enc)


def safe_show_account(account_label: str) -> str:
    view = get_broker_credentials_view(account_label)

    return (
        f"Account: {view.account_label}\n"
        f"Broker: {view.broker or '-'}\n"
        f"Platform: {view.platform or '-'}\n"
        f"Login: {view.login or '-'}\n"
        f"Server: {view.server or '-'}\n"
        f"Password: {'configured' if view.has_password else 'not configured'}"
    )
