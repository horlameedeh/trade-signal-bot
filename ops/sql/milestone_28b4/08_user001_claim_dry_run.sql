-- 28C.1 preview / Windows or MacBook snapshot / user001 claim dry-run
--
-- This script does not update anything.
--
-- It previews:
-- - current admin user
-- - current user001 slot
-- - canonical Vantage/FTMO broker rows
-- - current Vantage/FTMO terminal sessions
-- - target post-claim names and paths

WITH slot_user AS (
    SELECT user_id, telegram_user_id, display_name, identity_slot
    FROM users
    WHERE identity_slot = 'user001'
),
admin_user AS (
    SELECT user_id, telegram_user_id, display_name
    FROM users
    WHERE telegram_user_id = 7622982526
),
target_accounts AS (
    SELECT
      ba.account_id,
      ba.broker::text AS broker,
      ba.platform::text AS platform,
      ba.label,
      ba.user_id AS current_broker_user_id,
      ba.is_active,
      CASE lower(ba.broker::text)
        WHEN 'vantage' THEN 'prod-vantage-mt5-user001'
        WHEN 'ftmo' THEN 'prod-ftmo-mt5-user001'
      END AS target_terminal_name,
      CASE lower(ba.broker::text)
        WHEN 'vantage' THEN 'C:\Trading\Binaries\Vantage_MT5\terminal64.exe'
        WHEN 'ftmo' THEN 'C:\Trading\Binaries\FTMO_MT5\terminal64.exe'
      END AS target_terminal_path,
      CASE lower(ba.broker::text)
        WHEN 'vantage' THEN 'C:\Trading\Data\user001\vantage-mt5'
        WHEN 'ftmo' THEN 'C:\Trading\Data\user001\ftmo-mt5'
      END AS target_data_dir
    FROM broker_accounts ba
    WHERE ba.account_id IN (
      '95ad6253-1c4b-4c1a-b7fc-05941d76d550',
      '2200c898-5b23-4194-af12-b7ecf3aee68f'
    )
)
SELECT
  ta.account_id,
  ta.broker,
  ta.platform,
  ta.label,
  ta.is_active,
  ta.current_broker_user_id,
  au.user_id AS admin_user_id,
  su.user_id AS target_user001_user_id,
  su.telegram_user_id AS target_user001_telegram_user_id,
  ts.session_id AS current_session_id,
  ts.terminal_name AS current_terminal_name,
  ta.target_terminal_name,
  ts.terminal_path AS current_terminal_path,
  ta.target_terminal_path,
  ts.data_dir AS current_data_dir,
  ta.target_data_dir,
  ts.status AS current_session_status
FROM target_accounts ta
LEFT JOIN terminal_sessions ts
  ON ts.broker_account_id = ta.account_id
LEFT JOIN slot_user su
  ON TRUE
LEFT JOIN admin_user au
  ON TRUE
ORDER BY ta.broker;
