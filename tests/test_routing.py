import pytest

pytestmark = pytest.mark.integration

import os
import uuid
import time
from datetime import datetime, timezone

import pytest
from sqlalchemy import text

from app.db.session import SessionLocal
from app.routing.repository import RoutingRepository
from app.routing.router import Router
from app.ingest.storage import ingest_and_route_new_message


class FakeTG:
    def __init__(self):
        self.sent: list[tuple[int, str]] = []

    async def send_message(self, chat_id: int, text: str):
        self.sent.append((chat_id, text))


@pytest.fixture
def control_chat_id() -> int:
    v = os.getenv("TEST_CONTROL_CHAT_ID")
    return int(v) if v else -100999


@pytest.fixture
def db_session():
    with SessionLocal() as db:
        # Begin a transaction for the test. Some code under test calls db.commit();
        # use Session.rollback() at teardown which is safe even if the current
        # transaction has been closed by a commit.
        db.begin()
        try:
            yield db
        finally:
            db.rollback()


def _seed_broker_account(db_session, *, broker: str, platform: str = "mt5", label: str = "test") -> str:
    account_id = str(uuid.uuid4())

    db_session.execute(
        text(
            """
            INSERT INTO broker_accounts (account_id, broker, platform, kind, label, allowed_providers)
            VALUES (:account_id, :broker, :platform, 'personal_live', :label, ARRAY['fredtrading']::provider_code[])
            """
        ),
        {
            "account_id": account_id,
            "broker": broker,
            "platform": platform,
            "label": f"{label}-{broker}",
        },
    )
    return account_id


# -----------------------------
# Router-based tests
# -----------------------------

@pytest.mark.asyncio
async def test_mapped_channel_routes_correctly(db_session, control_chat_id):
    tg = FakeTG()
    repo = RoutingRepository(db_session)

    repo.set_chat_provider(chat_id=111, provider_code="fredtrading")

    ftmo_account_id = _seed_broker_account(db_session, broker="ftmo")
    repo.upsert_provider_account_route(provider_code="fredtrading", broker_account_id=ftmo_account_id)
    db_session.commit()

    router = Router(db_session, tg_client=tg, control_chat_id=control_chat_id)
    decision = await router.route_message(chat_id=111, telegram_message_id=555, raw_meta={"x": 1})

    assert decision is not None
    assert decision.provider_code == "fredtrading"
    assert decision.broker_account_id == ftmo_account_id
    assert tg.sent == []


@pytest.mark.asyncio
async def test_unmapped_channel_alerts_and_ignores(db_session, control_chat_id):
    tg = FakeTG()
    router = Router(db_session, tg_client=tg, control_chat_id=control_chat_id)

    decision = await router.route_message(chat_id=999, telegram_message_id=1, raw_meta={})
    assert decision is None
    assert len(tg.sent) == 1
    assert "Unknown chat_id 999" in tg.sent[0][1]


@pytest.mark.asyncio
async def test_provider_constraint_enforced(db_session):
    repo = RoutingRepository(db_session)
    traderscale_account_id = _seed_broker_account(db_session, broker="traderscale")

    with pytest.raises(ValueError):
        repo.upsert_provider_account_route("fredtrading", broker_account_id=traderscale_account_id)


# -----------------------------
# Ingest + routing integration tests
# -----------------------------

def _now():
    return datetime.now(timezone.utc)


def _seed_chat(db_session, chat_id: int, provider_code: str | None):
    db_session.execute(
        text(
            "INSERT INTO telegram_chats (chat_id, provider_code) VALUES (:c, :p) "
            "ON CONFLICT (chat_id) DO UPDATE SET provider_code = :p"
        ),
        {"c": chat_id, "p": provider_code},
    )


def _seed_provider_route(db_session, provider_code: str, broker_account_id: str, active: bool = True):
    """Seed provider_account_routes for tests under the history-friendly schema.

    - provider_code is no longer globally unique.
    - We rely on UNIQUE(provider_code, broker_account_id) for idempotent inserts.
    - When seeding an active route, we must ensure only one active route exists
      for provider_code (partial unique index).
    """

    if active:
        # Deactivate any existing active route first to avoid violating the
        # uq_provider_account_routes_one_active partial unique constraint.
        db_session.execute(
            text(
                """
                UPDATE provider_account_routes
                SET is_active=false, updated_at=now()
                WHERE provider_code = :p AND is_active = true;
                """
            ),
            {"p": provider_code},
        )

    # Ensure row exists (inactive by default), then set desired active flag.
    db_session.execute(
        text(
            """
            INSERT INTO provider_account_routes (provider_code, broker_account_id, is_active)
            VALUES (:p, CAST(:a AS uuid), false)
            ON CONFLICT (provider_code, broker_account_id) DO NOTHING;
            """
        ),
        {"p": provider_code, "a": broker_account_id},
    )

    db_session.execute(
        text(
            """
            UPDATE provider_account_routes
            SET is_active=:active, updated_at=now()
            WHERE provider_code=:p AND broker_account_id=CAST(:a AS uuid);
            """
        ),
        {"p": provider_code, "a": broker_account_id, "active": active},
    )

    if active:
        # Ensure all other routes are inactive (idempotent)
        db_session.execute(
            text(
                """
                UPDATE provider_account_routes
                SET is_active=false, updated_at=now()
                WHERE provider_code = :p AND broker_account_id <> CAST(:a AS uuid);
                """
            ),
            {"p": provider_code, "a": broker_account_id},
        )


def test_ingest_happy_path_routes(db_session):
    chat_id = 222
    provider = "fredtrading"

    _seed_chat(db_session, chat_id, provider)
    account_id = _seed_broker_account(db_session, broker="ftmo")
    _seed_provider_route(db_session, provider, account_id, True)
    db_session.commit()

    msg_id = int(time.time())

    result = ingest_and_route_new_message(
        chat_id=chat_id,
        chat_type="channel",
        title="test",
        username=None,
        is_control=False,
        message_id=msg_id,
        sender_id=1,
        date=_now(),
        message_text="hello",
        raw_json={"x": 1},
    )

    assert result.status == "ROUTED"
    assert result.provider_code == provider
    assert result.broker_account_id == account_id


def test_ingest_unknown_chat(db_session):
    chat_id = 333
    msg_id = int(time.time())

    result = ingest_and_route_new_message(
        chat_id=chat_id,
        chat_type="channel",
        title="test",
        username=None,
        is_control=False,
        message_id=msg_id,
        sender_id=1,
        date=_now(),
        message_text="hello",
        raw_json={"x": 1},
    )

    assert result.status == "IGNORED_UNKNOWN_CHAT"


def test_ingest_duplicate(db_session):
    chat_id = 444
    provider = "fredtrading"

    _seed_chat(db_session, chat_id, provider)
    account_id = _seed_broker_account(db_session, broker="ftmo")
    _seed_provider_route(db_session, provider, account_id, True)
    db_session.commit()

    msg_id = int(time.time())

    r1 = ingest_and_route_new_message(
        chat_id=chat_id,
        chat_type="channel",
        title="test",
        username=None,
        is_control=False,
        message_id=msg_id,
        sender_id=1,
        date=_now(),
        message_text="hello",
        raw_json={"x": 1},
    )

    r2 = ingest_and_route_new_message(
        chat_id=chat_id,
        chat_type="channel",
        title="test",
        username=None,
        is_control=False,
        message_id=msg_id,
        sender_id=1,
        date=_now(),
        message_text="hello again",
        raw_json={"x": 2},
    )

    assert r1.status == "ROUTED"
    assert r2.status == "DUPLICATE"
