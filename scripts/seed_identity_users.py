from __future__ import annotations

import os
from dataclasses import dataclass

from app.services.users import TradeBotUser, get_or_create_user, upsert_identity_slot_user


@dataclass(frozen=True)
class SeedUserSpec:
    identity_slot: str | None
    telegram_user_id: int | str
    display_name: str
    role: str = "user"


DEFAULT_USERS: tuple[SeedUserSpec, ...] = (
    SeedUserSpec(None, 7622982526, "TradeSignal Execution Admin", "admin"),
    SeedUserSpec("user001", "REPLACE_USER001_TELEGRAM_ID", "TradeSignal User 001"),
    SeedUserSpec("user002", "REPLACE_USER002_TELEGRAM_ID", "TradeSignal User 002"),
    SeedUserSpec("user003", "REPLACE_USER003_TELEGRAM_ID", "TradeSignal User 003"),
    SeedUserSpec("user004", "REPLACE_USER004_TELEGRAM_ID", "TradeSignal User 004"),
    SeedUserSpec("user005", "REPLACE_USER005_TELEGRAM_ID", "TradeSignal User 005"),
)


def resolve_telegram_user_id(value: int | str) -> int | None:
    if isinstance(value, int):
        return value

    raw = value.strip()
    if not raw:
        return None

    if raw.lstrip("-").isdigit():
        return int(raw)

    env_value = os.getenv(raw, "").strip()
    if env_value.lstrip("-").isdigit():
        return int(env_value)

    return None


def seed_users(users: tuple[SeedUserSpec, ...] = DEFAULT_USERS) -> tuple[list[TradeBotUser], list[TradeBotUser]]:
    created: list[TradeBotUser] = []
    reserved: list[TradeBotUser] = []

    for spec in users:
        telegram_user_id = resolve_telegram_user_id(spec.telegram_user_id)

        if spec.identity_slot is not None:
            reserved.append(
                upsert_identity_slot_user(
                    identity_slot=spec.identity_slot,
                    telegram_user_id=telegram_user_id,
                    display_name=spec.display_name,
                    role=spec.role,
                )
            )
            continue

        created.append(
            get_or_create_user(
                telegram_user_id=telegram_user_id,
                display_name=spec.display_name,
                role=spec.role,
            )
        )

    return created, reserved


def main() -> int:
    created, reserved = seed_users()

    for user in created:
        print(f"seeded telegram_user_id={user.telegram_user_id} role={user.role} name={user.display_name}")

    for user in reserved:
        if user.telegram_user_id is None:
            print(f"reserved identity_slot={user.identity_slot} name={user.display_name}")
        else:
            print(
                f"assigned identity_slot={user.identity_slot} telegram_user_id={user.telegram_user_id} "
                f"name={user.display_name}"
            )

    return 0


if __name__ == "__main__":
    raise SystemExit(main())