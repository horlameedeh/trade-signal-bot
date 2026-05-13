# Production DB Snapshot for MacBook Testing

Production DB data should not be assumed from the MacBook DB.

For realistic MacBook testing:
1. Export a Windows production DB snapshot.
2. Import into a local MacBook test database.
3. Never connect MacBook development tools directly to live production unless intentionally inspecting read-only state.
4. Never mirror broker binaries or terminal data folders to MacBook.

## Recommended snapshot rules

- Use snapshots for testing ownership logic.
- Redact secrets if any are present.
- Do not treat local MacBook `user_id` UUIDs as equal to Windows `user_id` UUIDs.
- Treat `telegram_user_id` as durable identity.
- Treat `identity_slot` as reserved slot identity.
- Treat `account_id` values from Windows as production inventory identifiers only.

## MacBook should not mirror

```text
C:\Trading\Binaries
C:\Trading\Data
```