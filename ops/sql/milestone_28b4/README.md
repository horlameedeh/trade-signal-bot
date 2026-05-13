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

## Audit script order

1. `01_schema_audit.sql`
2. `02_identity_audit.sql`
3. `03_windows_broker_inventory_audit.sql`
4. `04_windows_terminal_session_audit.sql`
5. `06_windows_terminal_path_standard_gap.sql`
6. `07_windows_terminal_path_mapping_audit.sql`
7. `08_user001_claim_dry_run.sql`

## Mutation script order

Run only on Windows production DB after snapshot:

1. `05_windows_canonical_freeze.sql`

## Windows execution example

```powershell
$env:PGPASSWORD = "tradebot_password"

psql -h localhost -p 5432 -U tradebot -d tradebot -f ops/sql/milestone_28b4/01_schema_audit.sql
psql -h localhost -p 5432 -U tradebot -d tradebot -f ops/sql/milestone_28b4/02_identity_audit.sql
psql -h localhost -p 5432 -U tradebot -d tradebot -f ops/sql/milestone_28b4/03_windows_broker_inventory_audit.sql
psql -h localhost -p 5432 -U tradebot -d tradebot -f ops/sql/milestone_28b4/04_windows_terminal_session_audit.sql
psql -h localhost -p 5432 -U tradebot -d tradebot -f ops/sql/milestone_28b4/07_windows_terminal_path_mapping_audit.sql
psql -h localhost -p 5432 -U tradebot -d tradebot -f ops/sql/milestone_28b4/08_user001_claim_dry_run.sql
```

## Production rule

Do not delete historical duplicate broker rows.
Do not pre-register dormant terminal sessions.
Do not mirror broker binaries/data folders to MacBook.
Run production mutation scripts only after a DB snapshot.