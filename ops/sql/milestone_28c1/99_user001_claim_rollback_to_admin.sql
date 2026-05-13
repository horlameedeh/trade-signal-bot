-- 28C.1 rollback / revert user001 Vantage/FTMO claim to admin ownership
--
-- Use only if 28C.1 claim migration needs to be reverted.
--
-- This does not restore from dump.
-- It logically reverts:
-- - user001 telegram_user_id back to NULL
-- - Vantage/FTMO broker ownership back to admin
-- - Vantage/FTMO terminal sessions back to pre-claim names and paths

BEGIN;

WITH admin_user AS (
    SELECT user_id
    FROM users
    WHERE telegram_user_id = 7622982526
)
UPDATE broker_accounts ba
SET
  user_id = au.user_id,
  is_active = TRUE,
  updated_at = now()
FROM admin_user au
WHERE ba.account_id IN (
  '95ad6253-1c4b-4c1a-b7fc-05941d76d550',
  '2200c898-5b23-4194-af12-b7ecf3aee68f'
);

WITH admin_user AS (
    SELECT user_id
    FROM users
    WHERE telegram_user_id = 7622982526
)
UPDATE terminal_sessions ts
SET
  user_id = au.user_id,
  terminal_name = 'prod-vantage-mt5',
  terminal_path = 'C:\Trading\Vantage_MT5\terminal64.exe',
  data_dir = 'C:\Trading\Vantage_MT5',
  updated_at = now()
FROM admin_user au
WHERE ts.broker_account_id = '95ad6253-1c4b-4c1a-b7fc-05941d76d550';

WITH admin_user AS (
    SELECT user_id
    FROM users
    WHERE telegram_user_id = 7622982526
)
UPDATE terminal_sessions ts
SET
  user_id = au.user_id,
  terminal_name = 'prod-ftmo-mt5',
  terminal_path = 'C:\Trading\FTMO_MT5\terminal64.exe',
  data_dir = 'C:\Trading\FTMO_MT5',
  updated_at = now()
FROM admin_user au
WHERE ts.broker_account_id = '2200c898-5b23-4194-af12-b7ecf3aee68f';

UPDATE users
SET
  telegram_user_id = NULL,
  display_name = 'TradeSignal User 001',
  is_active = TRUE,
  updated_at = now()
WHERE identity_slot = 'user001'
  AND telegram_user_id = 103751272;

SELECT
  ts.session_id,
  ts.terminal_name,
  ts.terminal_path,
  ts.data_dir,
  ts.status,
  ts.user_id AS terminal_user_id,
  ba.user_id AS broker_user_id,
  ba.broker,
  ba.platform
FROM terminal_sessions ts
JOIN broker_accounts ba
  ON ba.account_id = ts.broker_account_id
WHERE ts.broker_account_id IN (
  '95ad6253-1c4b-4c1a-b7fc-05941d76d550',
  '2200c898-5b23-4194-af12-b7ecf3aee68f'
)
ORDER BY ba.broker;

COMMIT;
