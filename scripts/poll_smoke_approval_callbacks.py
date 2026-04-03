from __future__ import annotations

import subprocess
import time

from app.telegram.control_bot import load_cfg
from app.telegram.bot_client import tg_get, tg_post
from app.services.approval_callbacks import handle_approval_callback


def _local_pollers() -> list[str]:
    try:
        p = subprocess.run(
            ["pgrep", "-af", r"app\.telegram\.control_bot|poll_smoke_approval_callbacks\.py"],
            capture_output=True,
            text=True,
            check=False,
        )
    except Exception:
        return []
    lines = [ln.strip() for ln in (p.stdout or "").splitlines() if ln.strip()]
    return lines


def _print_preflight(cfg) -> bool:
    try:
        info = tg_get(cfg, "getWebhookInfo")
        webhook = (info.get("result") or {}).get("url") or ""
        if webhook:
            print(f"Webhook is set: {webhook}")
    except Exception as e:
        print(f"Warning: getWebhookInfo failed: {e}")

    try:
        tg_post(cfg, "deleteWebhook", {"drop_pending_updates": False})
    except Exception as e:
        print(f"Warning: deleteWebhook failed: {e}")

    try:
        tg_get(cfg, "getUpdates", {"timeout": 0, "limit": 1})
        return True
    except Exception as e:
        msg = str(e)
        if "Conflict" not in msg or "getUpdates" not in msg:
            print(f"Preflight getUpdates failed: {e}")
            return False

        print("Preflight conflict: another getUpdates consumer is active for this bot token.")
        pollers = _local_pollers()
        if pollers:
            print("Likely local competing process(es):")
            for line in pollers:
                print(f"  {line}")
        print("Stop other poller(s), then run this script again.")
        print("Example: pkill -f app.telegram.control_bot")
        return False

def main() -> None:
    cfg, control_chat_id = load_cfg()
    offset = None

    if not _print_preflight(cfg):
        raise SystemExit(2)

    print("Polling for approval button clicks. Ctrl+C to stop.")
    conflict_count = 0
    while True:
        params = {"timeout": 25}
        if offset is not None:
            params["offset"] = offset

        try:
            data = tg_get(cfg, "getUpdates", params)
        except Exception as e:
            msg = str(e)
            if "Conflict" in msg and "getUpdates" in msg:
                conflict_count += 1
                print(
                    "Telegram getUpdates conflict: another poller/webhook is active. "
                    "Stop other bot instances or disable webhook, then retrying..."
                )
                if conflict_count % 3 == 0:
                    pollers = _local_pollers()
                    if pollers:
                        print("Detected local poller process(es):")
                        for line in pollers:
                            print(f"  {line}")
                        print("Stop them (for example: pkill -f app.telegram.control_bot)")
                time.sleep(3)
                continue
            raise

        conflict_count = 0

        for upd in data.get("result", []):
            offset = upd["update_id"] + 1

            cq = upd.get("callback_query")
            if not cq:
                continue

            msg = cq.get("message") or {}
            chat = msg.get("chat") or {}
            if chat.get("id") != control_chat_id:
                continue

            callback_data = cq.get("data")
            uid = (cq.get("from") or {}).get("id")
            message_id = msg.get("message_id")

            try:
                result = handle_approval_callback(
                    callback_data=callback_data,
                    telegram_user_id=uid,
                    control_chat_id=control_chat_id,
                    control_message_id=message_id,
                )

                tg_post(
                    cfg,
                    "answerCallbackQuery",
                    {"callback_query_id": cq["id"]},
                )

                tg_post(
                    cfg,
                    "sendMessage",
                    {
                        "chat_id": control_chat_id,
                        "text": f"Callback handled: ok={result.ok}, action={result.action.value}, created={result.control_action_created}, reason={result.reason}",
                    },
                )
            except Exception as e:
                tg_post(
                    cfg,
                    "answerCallbackQuery",
                    {"callback_query_id": cq["id"]},
                )
                tg_post(
                    cfg,
                    "sendMessage",
                    {
                        "chat_id": control_chat_id,
                        "text": f"Callback error: {repr(e)}",
                    },
                )

        time.sleep(1)

if __name__ == "__main__":
    main()
