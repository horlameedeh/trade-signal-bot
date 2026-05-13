-- 28C.1 / user001 claim dry-run
--
-- Claimant Telegram user ID:
--   103751272
--
-- This script does not mutate anything.

WITH claimant_conflict AS (
    SELECT
      user_id,
      telegram_user_id,
      display_name,
      role,
      identity_slot,
      is_active
    FROM users
    WHERE telegram_user_id = 103751272
),
slot_user AS (
    SELECT
      user_id,
      telegram_user_id,
      display_name,
      role,
      identity_slot,
      is_active
    FROM users
    WHERE identity_slot = 'user001'
),
target_accounts AS (
    SELECT
      ba.account_id,
      ba.broker::text AS broker,
      ba.platform::text AS platform,
      ba.label,
      ba.user_id AS current_broker_user_id,
      ba.is_active
    FROM broker_accounts ba
    WHERE ba.account_id IN (
      '95ad6253-1c4b-4c1a-b7fc-05941d76d550',
      '2200c898-5b23-4194-af12-b7ecf3aee68f'
    )
),
target_sessions AS (
    SELECT
      ts.session_id,
      ts.broker_account_id,
      ts.terminal_name,
      ts.terminal_path,
      ts.data_dir,
      ts.status,
      ts.user_id AS current_terminal_user_id
    FROM terminal_sessions ts
    WHERE ts.broker_account_id IN (
      '95ad6253-1c4b-4c1a-b7fc-05941d76d550',
      '2200c898-5b23-4194-af12-b7ecf3aee68f'
    )
)
SELECT 'claimant_conflict_check' AS section, *
FROM claimant_conflict
UNION ALL
SELECT 'slot_user_check' AS section, *
FROM slot_user
ORDER BY section;

SELECT
  ta.account_id,
  ta.broker,
  ta.platform,
  ta.label,
  ta.is_active,
  ta.current_broker_user_id,
  su.user_id AS target_user001_user_id,
  su.telegram_user_id AS current_user001_telegram_user_id,
  ts.session_id,
  ts.terminal_name AS current_terminal_name,
  CASE ta.broker
    WHEN 'vantage' THEN 'prod-vantage-mt5-user001'
    WHEN 'ftmo' THEN 'prod-ftmo-mt5-user001'
  END AS target_terminal_name,
  ts.terminal_path AS current_terminal_path,
  CASE ta.broker
    WHEN 'vantage' THEN 'C:\Trading\Binaries\Vantage_MT5\terminal64.exe'
    WHEN 'ftmo' THEN 'C:\Trading\Binaries\FTMO_MT5\terminal64.exe'
  END AS target_terminal_path,
  ts.data_dir AS current_data_dir,
  CASE ta.broker
    WHEN 'vantage' THEN 'C:\Trading\Data\user001\vantage-mt5'
    WHEN 'ftmo' THEN 'C:\Trading\Data\user001\ftmo-mt5'
  END AS target_data_dir,
  ts.status
FROM target_accounts ta
LEFT JOIN target_sessions ts
  ON ts.broker_account_id = ta.account_id
LEFT JOIN slot_user su
  ON TRUE
ORDER BY ta.broker;
