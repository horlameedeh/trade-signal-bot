# Milestone 28B.4 — Production Snapshot Workflow

## Purpose

MacBook development should test against production-like DB data using snapshots.

Do not mirror Windows broker binaries or terminal data folders to MacBook.

## Allowed to mirror

- repo/code
- migrations
- SQL audit scripts
- production DB snapshot into a local MacBook test database

## Not mirrored to MacBook

- `C:\Trading\Binaries`
- `C:\Trading\Data`
- running terminal sessions
- broker terminal processes

## Durable identity rule

- `users.telegram_user_id` is durable across environments.
- `users.user_id` is environment-local.
- Never assume a MacBook `users.user_id` equals a Windows `users.user_id`.

## Windows snapshot export

Run on Windows:

```powershell
$env:PGPASSWORD = "tradebot_password"
mkdir C:\Trading\DBSnapshots -Force

pg_dump `
  -h localhost `
  -p 5432 `
  -U tradebot `
  -d tradebot `
  -Fc `
  -f C:\Trading\DBSnapshots\tradebot_prod_snapshot.dump
```

## MacBook test DB restore

Run on MacBook.

Do not restore over the main dev DB unless that is intentional.

```bash
createdb tradebot_prod_snapshot_test 2>/dev/null || true

pg_restore \
  -h localhost \
  -p 5432 \
  -U tradebot \
  -d tradebot_prod_snapshot_test \
  --clean \
  --if-exists \
  ~/Trading/DBSnapshots/tradebot_prod_snapshot.dump
```

## MacBook snapshot audit example

```bash
PGPASSWORD=tradebot_password psql \
  -h localhost \
  -p 5432 \
  -U tradebot \
  -d tradebot_prod_snapshot_test \
  -f ops/sql/milestone_28b4/01_schema_audit.sql
```