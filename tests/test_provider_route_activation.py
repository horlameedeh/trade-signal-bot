import uuid

import pytest
from sqlalchemy import text

from app.db.session import SessionLocal
from app.routing.repository import RoutingRepository


pytestmark = pytest.mark.integration


@pytest.fixture
def db_session():
    with SessionLocal() as db:
        try:
            yield db
        finally:
            db.rollback()


def _seed_broker_account(db_session, *, broker: str, platform: str = "mt5", kind: str = "personal_live", label: str = "sim") -> str:
    """Insert a broker_accounts row and return its UUID account_id (as str)."""
    account_id = str(uuid.uuid4())
    db_session.execute(
        text(
            """
            INSERT INTO broker_accounts (account_id, broker, platform, kind, label, allowed_providers)
            VALUES (:account_id, :broker, :platform, :kind, :label, ARRAY[]::provider_code[])
            """
        ),
        {
            "account_id": account_id,
            "broker": broker,
            "platform": platform,
            "kind": kind,
            "label": f"{label}-{broker}",
        },
    )
    return account_id


def test_activate_provider_route_makes_target_active_and_others_inactive(db_session):
    repo = RoutingRepository(db_session)
    provider = "fredtrading"

    # Create two broker accounts to route to
    a1 = _seed_broker_account(db_session, broker="ftmo", label="simA")
    a2 = _seed_broker_account(db_session, broker="ftmo", label="simB")
    db_session.commit()

    # Activate first route
    repo.activate_provider_route(provider_code=provider, broker_account_id=a1)
    db_session.commit()

    # Verify exactly one active and it's a1
    rows = db_session.execute(
        text(
            """
            SELECT broker_account_id::text AS broker_account_id, is_active
            FROM provider_account_routes
            WHERE provider_code = :p
            ORDER BY is_active DESC, updated_at DESC;
            """
        ),
        {"p": provider},
    ).mappings().all()

    assert any(r["broker_account_id"] == a1 and r["is_active"] for r in rows)
    assert sum(1 for r in rows if r["is_active"]) == 1

    # Now activate second route; should flip active
    repo.activate_provider_route(provider_code=provider, broker_account_id=a2)
    db_session.commit()

    rows2 = db_session.execute(
        text(
            """
            SELECT broker_account_id::text AS broker_account_id, is_active
            FROM provider_account_routes
            WHERE provider_code = :p;
            """
        ),
        {"p": provider},
    ).mappings().all()

    assert any(r["broker_account_id"] == a2 and r["is_active"] for r in rows2)
    assert sum(1 for r in rows2 if r["is_active"]) == 1
    assert any(r["broker_account_id"] == a1 and (not r["is_active"]) for r in rows2)


def test_activate_provider_route_creates_row_if_missing(db_session):
    repo = RoutingRepository(db_session)
    provider = "mubeen"

    a1 = _seed_broker_account(db_session, broker="fundednext", label="sim")
    db_session.commit()

    # Ensure there is no row yet
    before = db_session.execute(
        text(
            """
            SELECT COUNT(*)
            FROM provider_account_routes
            WHERE provider_code=:p AND broker_account_id=CAST(:a AS uuid);
            """
        ),
        {"p": provider, "a": a1},
    ).scalar()
    assert before == 0

    repo.activate_provider_route(provider_code=provider, broker_account_id=a1)
    db_session.commit()

    after = db_session.execute(
        text(
            """
            SELECT is_active
            FROM provider_account_routes
            WHERE provider_code=:p AND broker_account_id=CAST(:a AS uuid);
            """
        ),
        {"p": provider, "a": a1},
    ).scalar()

    assert after is True

def test_db_enforces_only_one_active_route_per_provider(db_session):
    """
    This test proves the partial unique index works:

      uq_provider_account_routes_one_active
      UNIQUE(provider_code) WHERE is_active = true

    We bypass the repository helper and directly force two rows active.
    The second UPDATE should raise an integrity error.
    """
    import psycopg2
    from sqlalchemy.exc import IntegrityError

    repo = RoutingRepository(db_session)
    provider = "billionaire_club"

    a1 = _seed_broker_account(db_session, broker="traderscale", label="simA")
    a2 = _seed_broker_account(db_session, broker="traderscale", label="simB")
    db_session.commit()

    # Create both route rows (inactive by default)
    repo.activate_provider_route(provider_code=provider, broker_account_id=a1)
    db_session.commit()

    # Create second row but keep it inactive by creating then deactivating it
    # (activate_provider_route would flip, so we insert manually inactive)
    db_session.execute(
        text(
            """
            INSERT INTO provider_account_routes (provider_code, broker_account_id, is_active)
            VALUES (:p, CAST(:a AS uuid), false)
            ON CONFLICT (provider_code, broker_account_id) DO NOTHING;
            """
        ),
        {"p": provider, "a": a2},
    )
    db_session.commit()

    # Force a1 active
    db_session.execute(
        text(
            """
            UPDATE provider_account_routes
            SET is_active=true, updated_at=now()
            WHERE provider_code=:p AND broker_account_id=CAST(:a AS uuid);
            """
        ),
        {"p": provider, "a": a1},
    )
    db_session.commit()

    # Now try to force a2 active as well -> should violate partial unique index
    with pytest.raises(IntegrityError):
        db_session.execute(
            text(
                """
                UPDATE provider_account_routes
                SET is_active=true, updated_at=now()
                WHERE provider_code=:p AND broker_account_id=CAST(:a AS uuid);
                """
            ),
            {"p": provider, "a": a2},
        )
        db_session.commit()

    # Ensure session usable again
    db_session.rollback()
