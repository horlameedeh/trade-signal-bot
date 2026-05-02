from __future__ import annotations

from dataclasses import dataclass
from decimal import Decimal
from typing import Optional

from sqlalchemy import text

from app.db.session import SessionLocal
from app.execution.entry_policy import EntryPolicyInput, build_entry_plan
from app.risk.lot_sizing import LotSizingInput, resolve_lot_sizing
from app.services.symbol_aliases import resolve_broker_symbol


@dataclass(frozen=True)
class TradeWriterResult:
    family_id: str
    legs_created: int
    lot_per_leg: str
    total_lots: str
    is_stub: bool


def _infer_modifiers(row) -> list[str]:
    modifiers: list[str] = []

    risk_tag = row["risk_tag"]
    if risk_tag == "half":
        modifiers.append("HALF_RISK")
    elif risk_tag == "tiny":
        modifiers.append("TINY_RISK")
    elif risk_tag == "high":
        modifiers.append("HIGH_RISK")

    if row["reenter_tag"]:
        modifiers.append("REENTER")

    meta = row["meta"] or {}
    if isinstance(meta, dict):
        flags = meta.get("flags") or []
        for f in flags:
            if f in {"HALF_RISK", "HALF_SIZE", "HALF_OF_HALF", "TINY_RISK", "HIGH_RISK"}:
                modifiers.append(f)

    # preserve order but dedupe
    seen = set()
    out = []
    for m in modifiers:
        if m not in seen:
            seen.add(m)
            out.append(m)
    return out


def _infer_special_rule(row) -> str | None:
    text_value = (row["instructions"] or "").lower()
    if "trying something out" in text_value:
        return "trying_something_out"
    return None


def _resolve_account_context(db, account_id: str | None) -> dict[str, str | int]:
    if not account_id:
        raise RuntimeError("trade_plan.account_id missing for lot sizing")

    acc = db.execute(
        text(
            """
            SELECT
              ba.broker,
              ba.platform,
              ba.account_currency,
              COALESCE(ba.account_size, ba.equity_start, ba.equity_current, 10000) AS account_size
            FROM broker_accounts ba
            WHERE ba.account_id = CAST(:account_id AS uuid)
            LIMIT 1
            """
        ),
        {"account_id": account_id},
    ).mappings().first()

    if not acc:
        raise RuntimeError(f"broker_account not found: {account_id}")

    broker = str(acc["broker"])
    platform = str(acc["platform"])
    account_size = int(Decimal(str(acc["account_size"])))
    account_currency = str(acc["account_currency"] or "GBP")

    # Map broker to account_type expected by risk policy
    if broker in {"vantage", "startrader", "vtmarkets"}:
        account_type = "live"
    elif broker == "ftmo":
        account_type = "ftmo"
    elif broker == "traderscale":
        account_type = "traderscale"
    elif broker == "fundednext":
        account_type = "fundednext"
    else:
        raise RuntimeError(f"Unsupported broker for lot sizing policy: {broker}")

    return {
        "broker": broker,
        "platform": platform,
        "account_type": account_type,
        "account_size": account_size,
        "account_currency": account_currency,
    }


def create_trade_family_and_legs(
    *,
    source_msg_pk: str,
    total_lot: str | None = None,
) -> TradeWriterResult:
    with SessionLocal() as db:
        row = db.execute(
            text(
                """
                SELECT
                  ti.intent_id::text AS intent_id,
                  tp.plan_id::text AS plan_id,
                  tp.account_id::text AS account_id,
                  ti.provider,
                  ti.chat_id,
                  ti.source_msg_pk::text AS source_msg_pk,
                  ti.symbol_canonical,
                  ti.side::text AS side,
                  ti.order_type::text AS order_type,
                  ti.entry_price::text AS entry_price,
                  ti.sl_price::text AS sl_price,
                  ti.tp_prices,
                  ti.meta,
                  ti.parse_confidence,
                  ti.risk_tag::text AS risk_tag,
                  ti.is_swing,
                  ti.reenter_tag,
                  ti.instructions
                FROM trade_intents ti
                LEFT JOIN trade_plans tp ON tp.intent_id = ti.intent_id
                WHERE ti.source_msg_pk = CAST(:pk AS uuid)
                LIMIT 1
                """
            ),
            {"pk": source_msg_pk},
        ).mappings().first()

        if not row:
            raise RuntimeError(f"trade_intent not found for source_msg_pk={source_msg_pk}")

        existing = db.execute(
            text(
                """
                SELECT family_id::text
                FROM trade_families
                WHERE source_msg_pk = CAST(:pk AS uuid)
                LIMIT 1
                """
            ),
            {"pk": source_msg_pk},
        ).scalar()

        if existing:
            legs_count = db.execute(
                text("SELECT COUNT(*) FROM trade_legs WHERE family_id = CAST(:family_id AS uuid)"),
                {"family_id": existing},
            ).scalar() or 0

            return TradeWriterResult(
                family_id=existing,
                legs_created=int(legs_count),
                lot_per_leg="0",
                total_lots="0",
                is_stub=False,
            )

        tp_prices = row["tp_prices"] or []
        tp_count = len(tp_prices)
        is_stub = tp_count == 0 or row["sl_price"] is None

        if tp_count == 0:
            tp_count = 1

        if total_lot is None:
            account = _resolve_account_context(db, row["account_id"])
            modifiers = _infer_modifiers(row)
            special_rule = _infer_special_rule(row)

            symbol_result = resolve_broker_symbol(
                canonical_symbol=row["symbol_canonical"],
                broker=account["account_type"] if account["account_type"] != "live" else account["broker"],
                platform=str(account["platform"]),
            )
            if symbol_result.blocked:
                raise RuntimeError(
                    f"Symbol mapping blocked trade creation: {symbol_result.reason} "
                    f"(symbol={row['symbol_canonical']}, broker={symbol_result.broker}, platform={symbol_result.platform})"
                )

            sizing = resolve_lot_sizing(
                LotSizingInput(
                    provider=row["provider"],
                    account_type=str(account["account_type"]),
                    account_size=int(account["account_size"]),
                    modifiers=modifiers,
                    tp_count=tp_count,
                    broker=str(account["broker"]),
                    account_currency=str(account.get("account_currency") or "GBP"),
                    is_swing=bool(row["is_swing"]),
                    special_rule=special_rule,
                )
            )
            total_lots = sizing.total_lots
            lot_per_leg = sizing.per_leg_lots[0]
        else:
            total_lots = str(total_lot)
            lot_per_leg = str(Decimal(str(total_lot)) / Decimal(tp_count))

        management_rules = {
            "BE_AT_TP1": True,
            "SL_TO_ENTRY_AT_TP1": True,
        }

        family_row = db.execute(
            text(
                """
                INSERT INTO trade_families (
                  intent_id,
                  plan_id,
                  provider,
                  account_id,
                  chat_id,
                  source_msg_pk,
                  symbol_canonical,
                  broker_symbol,
                  side,
                  entry_price,
                  sl_price,
                  tp_count,
                  state,
                  is_stub,
                  management_rules,
                  meta
                )
                VALUES (
                                    CAST(:intent_id AS uuid),
                                    CAST(:plan_id AS uuid),
                  :provider,
                                    CAST(:account_id AS uuid),
                  :chat_id,
                                    CAST(:source_msg_pk AS uuid),
                  :symbol_canonical,
                                    :broker_symbol,
                  :side,
                  :entry_price,
                  :sl_price,
                  :tp_count,
                  :state,
                  :is_stub,
                  CAST(:management_rules AS jsonb),
                  '{}'::jsonb
                )
                RETURNING family_id::text
                """
            ),
            {
                "intent_id": row["intent_id"],
                "plan_id": row["plan_id"],
                "provider": row["provider"],
                "account_id": row["account_id"],
                "chat_id": row["chat_id"],
                "source_msg_pk": row["source_msg_pk"],
                "symbol_canonical": row["symbol_canonical"],
                "broker_symbol": symbol_result.resolved_symbol if total_lot is None else row["symbol_canonical"],
                "side": row["side"],
                "entry_price": row["entry_price"],
                "sl_price": row["sl_price"],
                "tp_count": tp_count,
                "state": "PENDING_UPDATE" if is_stub else "OPEN",
                "is_stub": is_stub,
                "management_rules": __import__("json").dumps(management_rules),
            },
        ).mappings().first()

        family_id = family_row["family_id"]

        tps = list(row["tp_prices"]) if row["tp_prices"] else [None]
        entry_plan = build_entry_plan(
            EntryPolicyInput(
                symbol=str(row["symbol_canonical"]),
                side=str(row["side"]),
                order_type=str(row["order_type"] or "market"),
                entry_price=str(row["entry_price"]),
                legs_count=len(tps),
            )
        )

        for idx, tp in enumerate(tps, start=1):
            requested_entry = entry_plan.requested_entries[idx - 1]
            placement_delay_ms = entry_plan.market_delays_ms[idx - 1]
            db.execute(
                text(
                    """
                    INSERT INTO trade_legs (
                      family_id,
                                            plan_id,
                                            idx,
                      leg_index,
                      entry_price,
                      requested_entry,
                      sl_price,
                      tp_price,
                      state,
                      lots,
                      placement_delay_ms
                    )
                    VALUES (
                                            CAST(:family_id AS uuid),
                                            CAST(:plan_id AS uuid),
                                            :idx,
                      :leg_index,
                      :entry_price,
                      :requested_entry,
                      :sl_price,
                      :tp_price,
                      'OPEN',
                      :lots,
                      :placement_delay_ms
                    )
                    """
                ),
                {
                    "family_id": family_id,
                    "plan_id": row["plan_id"],
                    "idx": idx,
                    "leg_index": idx,
                    "entry_price": row["entry_price"],
                    "requested_entry": requested_entry,
                    "sl_price": row["sl_price"],
                    "tp_price": tp,
                    "lots": lot_per_leg,
                    "placement_delay_ms": placement_delay_ms,
                },
            )

        db.commit()

    return TradeWriterResult(
        family_id=family_id,
        legs_created=tp_count,
        lot_per_leg=str(lot_per_leg),
        total_lots=str(total_lots),
        is_stub=is_stub,
    )
