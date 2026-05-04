"""Pytest configuration.

Ensures the repository root is importable so tests can import the `app` package
without requiring callers to set PYTHONPATH.
"""

from __future__ import annotations

import sys
from pathlib import Path
import pytest


ROOT = Path(__file__).resolve().parent
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))


TEST_CREDENTIAL_LABELS = (
    "cmd-ftmo-demo",
    "test-ftmo-secure",
)


@pytest.fixture
def db_session():
    from app.db.session import SessionLocal
    from sqlalchemy import text

    with SessionLocal() as db:
        db.execute(
            text("DELETE FROM broker_accounts WHERE label LIKE 'unit-%'")
        )
        db.commit()
        try:
            yield db
        finally:
            db.execute(
                text("DELETE FROM broker_accounts WHERE label LIKE 'unit-%'")
            )
            db.commit()


@pytest.fixture(autouse=True)
def _clean_test_broker_credentials():
    """Delete well-known test credential labels before each test to prevent
    stale encrypted data from a previous run with a different key causing
    InvalidToken failures."""
    try:
        from app.db.session import SessionLocal
        from sqlalchemy import text

        with SessionLocal() as db:
            db.execute(
                text(
                    "DELETE FROM broker_credentials WHERE account_label = ANY(:labels)"
                ),
                {"labels": list(TEST_CREDENTIAL_LABELS)},
            )
            db.commit()
    except Exception:
        pass
    yield
