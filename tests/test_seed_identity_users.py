from types import SimpleNamespace

from scripts.seed_identity_users import SeedUserSpec, resolve_telegram_user_id, seed_users


def test_resolve_telegram_user_id_accepts_int_and_numeric_string(monkeypatch):
    monkeypatch.delenv("REPLACE_USER001_TELEGRAM_ID", raising=False)

    assert resolve_telegram_user_id(123) == 123
    assert resolve_telegram_user_id("456") == 456


def test_resolve_telegram_user_id_uses_environment_placeholder(monkeypatch):
    monkeypatch.setenv("REPLACE_USER001_TELEGRAM_ID", "789")

    assert resolve_telegram_user_id("REPLACE_USER001_TELEGRAM_ID") == 789


def test_resolve_telegram_user_id_returns_none_for_unresolved_placeholder(monkeypatch):
    monkeypatch.delenv("REPLACE_USER001_TELEGRAM_ID", raising=False)

    assert resolve_telegram_user_id("REPLACE_USER001_TELEGRAM_ID") is None


def test_seed_users_skips_unresolved_placeholders(monkeypatch):
    seeded_calls: list[tuple[int, str, str]] = []
    reserved_calls: list[tuple[str, int | None, str, str]] = []

    def fake_get_or_create_user(*, telegram_user_id: int, display_name: str, role: str):
        seeded_calls.append((telegram_user_id, display_name, role))
        return SimpleNamespace(
            telegram_user_id=telegram_user_id,
            display_name=display_name,
            role=role,
            identity_slot=None,
        )

    def fake_upsert_identity_slot_user(*, identity_slot: str, telegram_user_id: int | None, display_name: str, role: str):
        reserved_calls.append((identity_slot, telegram_user_id, display_name, role))
        return SimpleNamespace(
            telegram_user_id=telegram_user_id,
            display_name=display_name,
            role=role,
            identity_slot=identity_slot,
        )

    monkeypatch.setattr("scripts.seed_identity_users.get_or_create_user", fake_get_or_create_user)
    monkeypatch.setattr("scripts.seed_identity_users.upsert_identity_slot_user", fake_upsert_identity_slot_user)

    created, reserved = seed_users(
        (
            SeedUserSpec(None, 7622982526, "TradeSignal Execution Admin", "admin"),
            SeedUserSpec("user001", "REPLACE_USER001_TELEGRAM_ID", "TradeSignal User 001"),
        )
    )

    assert len(created) == 1
    assert seeded_calls == [(7622982526, "TradeSignal Execution Admin", "admin")]
    assert reserved_calls == [("user001", None, "TradeSignal User 001", "user")]
    assert len(reserved) == 1