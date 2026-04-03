#!/usr/bin/env bash
set -euo pipefail

mkdir -p app/routing app/control tests docs scripts

# Non-destructive by default: don't overwrite any existing files.
# To force overwrite, run: FORCE=1 ./scripts/milestone2_scaffold.sh
: "${FORCE:=0}"

write_file() {
  local path="$1"
  shift

  if [[ "$FORCE" != "1" && -e "$path" ]]; then
    echo "↩︎ exists, skipping: $path"
    return 0
  fi

  # shellcheck disable=SC2068
  cat > "$path" <<EOF
$@
EOF
  echo "✅ wrote: $path"
}

write_file docs/milestone2_routing.md "# Milestone 2 — Routing: Channel → Provider → Account

## Goal
Deterministic routing:
- chat_id → provider_code
- provider_code → broker_account_id
- missing mapping => ignore + alert Control Chat
- persist routing decisions in Postgres (auditable)

## Admin Commands (Control Chat only)
- !addchannel <provider> <channel_id>
- !removechannel <provider> <channel_id>
- !showrouting

## Database
Tables:
- telegram_chats: (chat_id, provider_code, is_control_chat)
- provider_account_routes (provider_code → broker_account_id)
- routing_decisions (audit log)"

# Code stubs
write_file app/routing/constants.py "PROVIDER_CODES = {\"fredtrading\", \"billionaire_club\", \"mubeen\"}

PROVIDER_ALLOWED_BROKER_NAME = {
    \"fredtrading\": \"FTMO\",
    \"billionaire_club\": \"Traderscale\",
    \"mubeen\": \"FundedNext\",
}"

write_file app/control/notify.py "from __future__ import annotations
from typing import Protocol

class TelegramClient(Protocol):
    async def send_message(self, chat_id: int, text: str) -> None: ...

async def send_control_alert(tg: TelegramClient, control_chat_id: int, text: str) -> None:
    await tg.send_message(control_chat_id, f\"🚨 ROUTING ALERT\\n{text}\")"

write_file app/routing/repository.py "# Paste the repository implementation from the chat response here."
write_file app/routing/router.py "# Paste the router implementation from the chat response here."
write_file app/routing/admin_commands.py "# Paste the admin commands implementation from the chat response here."
write_file tests/test_routing.py "# Paste the test scaffolding from the chat response here."

echo "Done. (FORCE=$FORCE)"
