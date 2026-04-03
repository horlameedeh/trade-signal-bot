from __future__ import annotations

from sqlalchemy import text

from app.db.session import SessionLocal
from app.decision.engine import decide_signal
from app.decision.models import DecisionContext
from app.parsing.parser import parse_message
from app.services.approvals import create_approval_if_missing
from app.telegram.control_bot import load_cfg
from app.telegram.bot_client import tg_post


SOURCE_MSG_PK = "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"


def main() -> None:
    cfg, control_chat_id = load_cfg()

    signal_text = """High risk

XAUUSD BUY NOW
Enter 4603
SL 4597
TP1 4606
TP2 4610
TP3 4613
TP4 4626
"""

    parsed = parse_message("mubeen", signal_text)
    decision = decide_signal(
        DecisionContext(
            provider_code="mubeen",
            parsed=parsed,
            duplicate=False,
            risk_checks_pass=True,
        )
    )

    # Ensure an intent + plan exist so approvals can attach properly
    with SessionLocal() as db:
        db.execute(
            text(
                """
                INSERT INTO telegram_chats (chat_id, provider_code)
                VALUES (-1002298510219, 'mubeen')
                ON CONFLICT (chat_id) DO UPDATE SET provider_code='mubeen'
                """
            )
        )
        db.execute(
            text(
                """
                INSERT INTO telegram_messages (msg_pk, chat_id, message_id, text, raw_json)
                VALUES (
                  CAST(:pk AS uuid),
                  -1002298510219,
                  990001,
                  :txt,
                  '{}'::jsonb
                )
                ON CONFLICT (chat_id, message_id) DO NOTHING
                """
            ),
            {"pk": SOURCE_MSG_PK, "txt": signal_text},
        )
        db.execute(
            text(
                """
                INSERT INTO trade_intents (
                  provider, chat_id, source_msg_pk, source_message_id, dedupe_hash,
                  parse_confidence, symbol_canonical, symbol_raw, side, order_type,
                  entry_price, sl_price, tp_prices, has_runner, risk_tag,
                  is_scalp, is_swing, is_unofficial, reenter_tag, instructions, meta
                )
                VALUES (
                  'mubeen',
                  -1002298510219,
                  CAST(:pk AS uuid),
                  990001,
                  'smoke-approval-dedupe',
                  0.900,
                  'XAUUSD',
                  'XAUUSD',
                  'buy',
                  'market',
                  4603,
                  4597,
                  ARRAY[4606,4610,4613,4626]::numeric(18,10)[],
                  false,
                  'high',
                  false,
                  false,
                  false,
                  false,
                  :txt,
                  '{}'::jsonb
                )
                ON CONFLICT (source_msg_pk) DO NOTHING
              """
            ),
            {"pk": SOURCE_MSG_PK, "txt": signal_text},
        )
        db.execute(
            text(
              """
                INSERT INTO trade_plans (
                  intent_id, account_id, policy_outcome, requires_approval, policy_reasons
                )
                SELECT
                  ti.intent_id,
                  COALESCE(
                    (
                      SELECT par.broker_account_id
                      FROM provider_account_routes par
                      WHERE par.provider_code = CAST(ti.provider AS text)
                        AND par.is_active = true
                      LIMIT 1
                    ),
                    (
                      SELECT ba.account_id
                      FROM broker_accounts ba
                      WHERE ba.is_active = true
                      LIMIT 1
                    )
                  ),
                  'require_approval'::policy_outcome,
                  true,
                  ARRAY['approval_required']::text[]
                FROM trade_intents ti
                WHERE ti.source_msg_pk = CAST(:pk AS uuid)
                  AND NOT EXISTS (
                    SELECT 1 FROM trade_plans tp WHERE tp.intent_id = ti.intent_id
                  )
                """
            ),
            {"pk": SOURCE_MSG_PK},
        )
        db.commit()

    card = create_approval_if_missing(
        source_msg_pk=SOURCE_MSG_PK,
        provider_code="mubeen",
        parsed=parsed,
        decision=decision,
        control_chat_id=control_chat_id,
        control_message_id=None,
    )

    keyboard = {
        "inline_keyboard": [
            [
                {"text": "✅ Place trade", "callback_data": card.callback_place},
                {"text": "❌ Ignore", "callback_data": card.callback_ignore},
                {"text": "⏳ Snooze", "callback_data": card.callback_snooze},
            ]
        ]
    }

    resp = tg_post(
        cfg,
        "sendMessage",
        {
            "chat_id": control_chat_id,
            "text": card.message,
            "reply_markup": keyboard,
        },
    )

    message_id = resp["result"]["message_id"]

    # Update approvals row with sent control message id if missing
    with SessionLocal() as db:
        db.execute(
        text(
          """
            UPDATE approvals
            SET control_chat_id = :chat_id,
                control_message_id = :message_id
            WHERE notes LIKE :fp_like
          """
        ),
            {
                "chat_id": control_chat_id,
                "message_id": message_id,
                "fp_like": f"%Fingerprint: {card.callback_place.split(':')[-1]}%",
            },
        )
        db.commit()

    print("Sent smoke approval card.")
    print("control_chat_id:", control_chat_id)
    print("control_message_id:", message_id)
    print("callback_place :", card.callback_place)
    print("callback_ignore:", card.callback_ignore)
    print("callback_snooze:", card.callback_snooze)


if __name__ == "__main__":
    main()
