from __future__ import annotations

import json
from dataclasses import dataclass
from decimal import Decimal, ROUND_DOWN

from sqlalchemy import text

from app.db.session import SessionLocal


@dataclass(frozen=True)
class LotRoundingConfig:
    min_lot: Decimal = Decimal("0.01")
    lot_step: Decimal = Decimal("0.01")


@dataclass(frozen=True)
class TradeWriterResult:
    family_id: str
    legs_created: int
    lot_per_leg: str
    is_stub: bool


def _round_lot(value: Decimal, cfg: LotRoundingConfig) -> Decimal:
    if value < cfg.min_lot:
        return cfg.min_lot
    steps = (value / cfg.lot_step).quantize(Decimal("1"), rounding=ROUND_DOWN)
    rounded = steps * cfg.lot_step
    return rounded if rounded >= cfg.min_lot else cfg.min_lot


def _even_split(total_lot: Decimal, legs_count: int, cfg: LotRoundingConfig) -> Decimal:
    if legs_count <= 0:
        raise ValueError("legs_count must be > 0")
    raw = total_lot / Decimal(legs_count)
    return _round_lot(raw, cfg)


def create_trade_family_and_legs(
    *,
    source_msg_pk: str,
    total_lot: str,
    rounding_cfg: LotRoundingConfig | None = None,
) -> TradeWriterResult:
    rounding_cfg = rounding_cfg or LotRoundingConfig()

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
                  ti.entry_price::text AS entry_price,
                  ti.sl_price::text AS sl_price,
                  ti.tp_prices,
                  ti.meta,
                  ti.parse_confidence
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
                is_stub=False,
            )

        tp_prices = row["tp_prices"] or []
        tp_count = len(tp_prices)
        is_stub = tp_count == 0 or row["sl_price"] is None

        if tp_count == 0:
            tp_count = 1

        total_lot_dec = Decimal(str(total_lot))
        lot_per_leg = _even_split(total_lot_dec, tp_count, rounding_cfg)

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
                "side": row["side"],
                "entry_price": row["entry_price"],
                "sl_price": row["sl_price"],
                "tp_count": tp_count,
                "state": "PENDING_UPDATE" if is_stub else "OPEN",
                "is_stub": is_stub,
                "management_rules": json.dumps(management_rules),
            },
        ).mappings().first()

        family_id = family_row["family_id"]
        tps = list(row["tp_prices"]) if row["tp_prices"] else [None]

        for idx, tp in enumerate(tps, start=1):
            db.execute(
                text(
                    """
                    INSERT INTO trade_legs (
                      family_id,
                                            plan_id,
                                            idx,
                      leg_index,
                      entry_price,
                      sl_price,
                      tp_price,
                      state,
                                            lots
                    )
                    VALUES (
                      CAST(:family_id AS uuid),
                                            CAST(:plan_id AS uuid),
                                            :idx,
                      :leg_index,
                      :entry_price,
                      :sl_price,
                      :tp_price,
                      'OPEN',
                                            :lots
                    )
                    """
                ),
                {
                    "family_id": family_id,
                                        "plan_id": row["plan_id"],
                                        "idx": idx,
                    "leg_index": idx,
                    "entry_price": row["entry_price"],
                    "sl_price": row["sl_price"],
                    "tp_price": tp,
                                        "lots": str(lot_per_leg),
                },
            )

        db.commit()

    return TradeWriterResult(
        family_id=family_id,
        legs_created=tp_count,
        lot_per_leg=str(lot_per_leg),
        is_stub=is_stub,
    )
