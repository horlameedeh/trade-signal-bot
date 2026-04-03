from __future__ import annotations

import argparse
import json
from dataclasses import asdict

from app.parsing.service import parse_and_persist_message


def main() -> int:
    ap = argparse.ArgumentParser(description="Parse + persist a telegram message by msg_pk")
    ap.add_argument("msg_pk", help="telegram_messages.msg_pk UUID")
    args = ap.parse_args()

    result = parse_and_persist_message(args.msg_pk)
    print(json.dumps(asdict(result), indent=2, default=str))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
