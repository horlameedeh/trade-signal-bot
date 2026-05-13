# Milestone 28 — Production Execution Standard

## Environment Roles

### MacBook
- Development only
- Repo validation
- DB inspection
- Migration testing
- Production DB snapshot testing
- No broker terminals
- No broker binaries
- No production terminal data folders

### Windows PC
- Production terminal host
- MT4/MT5 binaries
- Terminal data directories
- Production terminal session registration
- Heartbeats
- Live routing execution

## Durable Identity Rules

- `users.telegram_user_id` is durable cross-environment identity.
- `users.user_id` is environment-local only.
- `broker_accounts.user_id` must be set before live execution is trusted.
- `terminal_sessions.user_id` must match `broker_accounts.user_id`.
- Folder names are not ownership truth.
- DB ownership is source of truth.

## Admin Identity

- Telegram user id: `7622982526`
- Display name: `TradeSignal Execution Admin`
- Role: `admin`

## Reserved Slot Standard

| Slot | Display Name |
|---|---|
| user001 | TradeSignal User 001 |
| user002 | TradeSignal User 002 |
| user003 | TradeSignal User 003 |
| user004 | TradeSignal User 004 |
| user005 | TradeSignal User 005 |

Reserved slots:
- exist in DB
- have `identity_slot` set
- have `telegram_user_id = NULL` until claimed

## Terminal Naming

Pattern:

```text
prod-<broker>-<platform>-<slot>
```