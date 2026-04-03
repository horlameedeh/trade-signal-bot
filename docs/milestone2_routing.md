# Milestone 2 — Routing: Channel → Provider → Account

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
- routing_decisions (audit log)
