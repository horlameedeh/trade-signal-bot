from __future__ import annotations

import json

from app.decision.engine import decide_signal
from app.decision.models import DecisionContext
from app.parsing.parser import parse_message
from app.services.approvals import create_approval_if_missing, build_approval_card

SOURCE_MSG_PK = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"

def main() -> None:
    text = """High risk

XAUUSD BUY NOW
Enter 4603
SL 4597
TP1 4606
TP2 4610
TP3 4613
TP4 4626
"""
    parsed = parse_message("mubeen", text)
    decision = decide_signal(
        DecisionContext(
            provider_code="mubeen",
            parsed=parsed,
            duplicate=False,
            risk_checks_pass=True,
        )
    )

    card = build_approval_card(
        source_msg_pk=SOURCE_MSG_PK,
        provider_code="mubeen",
        parsed=parsed,
        decision=decision,
    )

    create_approval_if_missing(
        source_msg_pk=SOURCE_MSG_PK,
        provider_code="mubeen",
        parsed=parsed,
        decision=decision,
    )

    print("=== APPROVAL CARD ===")
    print(card.message)
    print()
    print("callback_place :", card.callback_place)
    print("callback_ignore:", card.callback_ignore)
    print("callback_snooze:", card.callback_snooze)
    print()
    print("Done.")

if __name__ == "__main__":
    main()
