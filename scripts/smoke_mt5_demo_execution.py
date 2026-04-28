from __future__ import annotations

import argparse
import uuid
from decimal import Decimal

from sqlalchemy import text

from app.db.session import SessionLocal
from app.execution.http_node import HttpExecutionNode
from app.execution.live_executor import execute_family_live
from app.execution.node_registry import get_active_execution_node


def seed_demo_family(*, broker: str, platform: str, symbol: str, broker_symbol: str) -> str:
    chat_id = -1001239815745
    source_msg_pk = str(uuid.uuid4())
    source_message_id = 870000 + (uuid.UUID(source_msg_pk).int % 99999)
    account_id = str(uuid.uuid4())
    intent_id = str(uuid.uuid4())
    plan_id = str(uuid.uuid4())
    family_id = str(uuid.uuid4())

    with SessionLocal() as db:
        db.execute(
            text("""
            INSERT INTO symbols (canonical, asset_class)
            VALUES (:symbol, 'metal')
            ON CONFLICT (canonical) DO NOTHING
            """),
            {"symbol": symbol},
        )

        db.execute(
            text("""
            INSERT INTO broker_accounts (
              account_id, broker, platform, kind, label,
              allowed_providers, equity_start, is_active
            )
            VALUES (
              CAST(:account_id AS uuid), :broker, :platform, 'personal_live',
              'MT5 demo smoke', ARRAY[]::provider_code[], 10000, true
            )
            """),
            {"account_id": account_id, "broker": broker, "platform": platform},
        )

        db.execute(
            text("""
            INSERT INTO telegram_chats (chat_id, provider_code)
            VALUES (:chat_id, 'fredtrading')
            ON CONFLICT (chat_id) DO UPDATE SET provider_code='fredtrading'
            """),
            {"chat_id": chat_id},
        )

        db.execute(
            text("""
            INSERT INTO telegram_messages (msg_pk, chat_id, message_id, text, raw_json)
            VALUES (
              CAST(:source_msg_pk AS uuid), :chat_id, :message_id,
              'MT5 demo execution smoke', '{}'::jsonb
            )
            """),
            {
                "source_msg_pk": source_msg_pk,
                "chat_id": chat_id,
                "message_id": source_message_id,
            },
        )

        db.execute(
            text("""
            INSERT INTO trade_intents (
              intent_id, provider, chat_id, source_msg_pk, source_message_id, dedupe_hash,
              parse_confidence, symbol_canonical, symbol_raw, side, order_type,
              entry_price, sl_price, tp_prices, has_runner, risk_tag,
              is_scalp, is_swing, is_unofficial, reenter_tag, instructions, meta
            )
            VALUES (
              CAST(:intent_id AS uuid), 'fredtrading', :chat_id,
              CAST(:source_msg_pk AS uuid), :message_id, :dedupe_hash,
              0.950, :symbol, :symbol, 'buy', 'market',
              NULL, NULL, ARRAY[]::numeric(18,10)[], false, 'normal',
              false, false, false, false, 'MT5 demo execution smoke', '{}'::jsonb
            )
            """),
            {
                "intent_id": intent_id,
                "chat_id": chat_id,
                "source_msg_pk": source_msg_pk,
                "message_id": source_message_id,
                "dedupe_hash": f"mt5-demo-{source_msg_pk}",
                "symbol": symbol,
            },
        )

        db.execute(
            text("""
            INSERT INTO trade_plans (
              plan_id, intent_id, account_id, policy_outcome, requires_approval, policy_reasons
            )
            VALUES (
              CAST(:plan_id AS uuid), CAST(:intent_id AS uuid), CAST(:account_id AS uuid),
              'allow'::policy_outcome, false, ARRAY['mt5_demo_smoke']::text[]
            )
            """),
            {"plan_id": plan_id, "intent_id": intent_id, "account_id": account_id},
        )

        db.execute(
            text("""
            INSERT INTO trade_families (
              family_id, intent_id, plan_id, provider, account_id, chat_id, source_msg_pk,
              symbol_canonical, broker_symbol, side, entry_price, sl_price, tp_count,
              state, is_stub, management_rules, meta
            )
            VALUES (
              CAST(:family_id AS uuid), CAST(:intent_id AS uuid), CAST(:plan_id AS uuid),
              'fredtrading', CAST(:account_id AS uuid), :chat_id, CAST(:source_msg_pk AS uuid),
              :symbol, :broker_symbol, 'buy', NULL, NULL, 1,
              'OPEN', false, '{}'::jsonb, '{"smoke":"mt5_demo"}'::jsonb
            )
            """),
            {
                "family_id": family_id,
                "intent_id": intent_id,
                "plan_id": plan_id,
                "account_id": account_id,
                "chat_id": chat_id,
                "source_msg_pk": source_msg_pk,
                "symbol": symbol,
                "broker_symbol": broker_symbol,
            },
        )

        db.execute(
            text("""
            INSERT INTO trade_legs (
              leg_id, family_id, plan_id, idx, leg_index, entry_price, requested_entry,
              sl_price, tp_price, lots, state, placement_delay_ms
            )
            VALUES (
              gen_random_uuid(), CAST(:family_id AS uuid), CAST(:plan_id AS uuid),
              1, 1, NULL, NULL, NULL, NULL, 0.01, 'OPEN', 0
            )
            """),
            {"family_id": family_id, "plan_id": plan_id},
        )

        db.commit()

    return family_id


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--broker", default="fundednext")
    parser.add_argument("--platform", default="mt5")
    parser.add_argument("--symbol", default="XAUUSD")
    parser.add_argument("--broker-symbol", default="XAUUSD")
    parser.add_argument("--execute", action="store_true")
    args = parser.parse_args()

    node = get_active_execution_node(broker=args.broker, platform=args.platform)
    print(f"node={node.name} {node.base_url}")

    family_id = seed_demo_family(
        broker=args.broker,
        platform=args.platform,
        symbol=args.symbol,
        broker_symbol=args.broker_symbol,
    )
    print(f"family_id={family_id}")

    if not args.execute:
        print("DRY PREP ONLY. Re-run with --execute after enabling TRADEBOT_LIVE_TRADING_ENABLED=true on Windows.")
        return 0

    result = execute_family_live(
        family_id=family_id,
        adapter=HttpExecutionNode(node.base_url, timeout=30),
    )
    print(result)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
