# Milestone 28B.4 SQL Pack

## Known schema names

- `users.user_id`
- `users.telegram_user_id`
- `users.identity_slot`
- `broker_accounts.account_id`
- `broker_accounts.user_id`
- `broker_accounts.broker`
- `broker_accounts.platform`
- `broker_accounts.is_active`
- `terminal_sessions.session_id`
- `terminal_sessions.broker_account_id`
- `terminal_sessions.user_id`
- `terminal_sessions.status`
- `terminal_sessions.terminal_name`
- `terminal_sessions.terminal_path`
- `terminal_sessions.data_dir`

## Script order

1. `01_schema_audit.sql`
2. `02_identity_audit.sql`
3. `03_windows_broker_inventory_audit.sql`
4. `04_windows_terminal_session_audit.sql`

## Execution example

```bash
PGPASSWORD=tradebot_password psql -h localhost -p 5432 -U tradebot -d tradebot -f ops/sql/milestone_28b4/01_schema_audit.sql
```