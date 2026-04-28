from __future__ import annotations

import argparse
import json
import uuid

from app.execution.base import OrderLegRequest
from app.execution.http_node import HttpExecutionNode


def main() -> int:
    parser = argparse.ArgumentParser(description="Send one tiny MT5 execution smoke order to Windows node.")
    parser.add_argument("--url", required=True, help="Windows node base URL, e.g. http://192.168.178.135:8008")
    parser.add_argument("--symbol", default="XAUUSD")
    parser.add_argument("--side", choices=["buy", "sell"], default="buy")
    parser.add_argument("--lots", default="0.01")
    parser.add_argument("--sl")
    parser.add_argument("--tp")
    parser.add_argument("--confirm", action="store_true")
    args = parser.parse_args()

    if not args.confirm:
        raise SystemExit("Refusing to send order without --confirm")

    family_id = str(uuid.uuid4())
    leg_id = str(uuid.uuid4())

    node = HttpExecutionNode(args.url)

    leg = OrderLegRequest(
        leg_id=leg_id,
        family_id=family_id,
        broker="ftmo",
        platform="mt5",
        broker_symbol=args.symbol,
        side=args.side,
        order_type="market",
        lots=args.lots,
        requested_entry=None,
        sl_price=args.sl,
        tp_price=args.tp,
        magic=999001,
        comment=f"tradebot-smoke:{family_id}:{leg_id}",
    )

    # Pre-flight: check node health before attempting order
    print(f"[INFO] Checking node health at {args.url}/health ...")
    try:
        import requests as _requests
        health_r = _requests.get(f"{args.url}/health", timeout=5)
        health = health_r.json()
        print(f"[INFO] Health: ok={health.get('ok')} platform={health.get('platform')} "
              f"trading_enabled={health.get('trading_enabled')} detail={health.get('detail')}")
        if not health.get("trading_enabled"):
            raise SystemExit(
                f"[BLOCKED] Node reports trading_enabled=false.\n"
                f"  Set TRADEBOT_LIVE_TRADING_ENABLED=true in the Windows node .env and restart the node."
            )
    except SystemExit:
        raise
    except Exception as e:
        print(f"[WARN] Health check failed ({e}), proceeding anyway...")

    print("[DEBUG] Sending order leg:")
    print(json.dumps(leg.__dict__, indent=2))

    try:
        receipts = node.open_legs([leg])
        for r in receipts:
            print(r)
    except Exception as e:
        print(f"\n[ERROR] Request failed: {e}")
        if hasattr(e, 'response') and e.response is not None:
            try:
                print(f"[ERROR] Response body: {e.response.text}")
            except Exception:
                pass
        raise

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
