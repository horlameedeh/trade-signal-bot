"""
Bot API client helpers (requests-based).
"""
from __future__ import annotations
from dataclasses import dataclass
from typing import Any, Dict, Optional
import os
import requests

@dataclass
class BotCfg:
    token: str
    api_base: str

def load_bot_cfg() -> BotCfg:
    token = os.environ["TELEGRAM_BOT_TOKEN"]
    return BotCfg(token=token, api_base=f"https://api.telegram.org/bot{token}")


def _telegram_error_from_response(r: requests.Response) -> RuntimeError:
    status = r.status_code
    try:
        data = r.json()
    except Exception:
        body = (r.text or "").strip()
        return RuntimeError(f"Telegram HTTP {status}: {body}")

    description = data.get("description")
    error_code = data.get("error_code", status)
    parameters = data.get("parameters")
    details = f"Telegram API error {error_code}: {description or data}"
    if parameters:
        details = f"{details} (parameters={parameters})"
    return RuntimeError(details)

def tg_get(cfg: BotCfg, method: str, params: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
    r = requests.get(f"{cfg.api_base}/{method}", params=params or {}, timeout=35)
    if not r.ok:
        raise _telegram_error_from_response(r)
    data = r.json()
    if not data.get("ok"):
        description = data.get("description")
        error_code = data.get("error_code")
        raise RuntimeError(f"Telegram API error {error_code}: {description or data}")
    return data

def tg_post(cfg: BotCfg, method: str, payload: Dict[str, Any]) -> Dict[str, Any]:
    r = requests.post(f"{cfg.api_base}/{method}", json=payload, timeout=35)
    if not r.ok:
        raise _telegram_error_from_response(r)
    data = r.json()
    if not data.get("ok"):
        description = data.get("description")
        error_code = data.get("error_code")
        raise RuntimeError(f"Telegram API error {error_code}: {description or data}")
    return data
