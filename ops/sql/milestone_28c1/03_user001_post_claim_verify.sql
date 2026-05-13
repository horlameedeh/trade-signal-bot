-- 28C.1 / post-claim verification

SELECT
  user_id,
  telegram_user_id,
  display_name,
  role,
  identity_slot,
  is_active
FROM users
WHERE identity_slot = 'user001';

SELECT
  ba.account_id,
  ba.broker,
  ba.platform,
  ba.label,
  ba.user_id AS broker_user_id,
  u.identity_slot,
  u.telegram_user_id,
  ba.is_active
FROM broker_accounts ba
JOIN users u
  ON u.user_id = ba.user_id
WHERE ba.account_id IN (
  '95ad6253-1c4b-4c1a-b7fc-05941d76d550',
  '2200c898-5b23-4194-af12-b7ecf3aee68f'
)
ORDER BY ba.broker;

SELECT
  ts.session_id,
  ts.terminal_name,
  ts.terminal_path,
  ts.data_dir,
  ts.status,
  ts.user_id AS terminal_user_id,
  ba.user_id AS broker_user_id,
  u.identity_slot,
  u.telegram_user_id,
  ba.broker,
  ba.platform
FROM terminal_sessions ts
JOIN broker_accounts ba
  ON ba.account_id = ts.broker_account_id
JOIN users u
  ON u.user_id = ts.user_id
WHERE ts.broker_account_id IN (
  '95ad6253-1c4b-4c1a-b7fc-05941d76d550',
  '2200c898-5b23-4194-af12-b7ecf3aee68f'
)
ORDER BY ba.broker;

-- Should return 0 rows.
SELECT
  ts.session_id,
  ts.terminal_name,
  ts.user_id AS terminal_user_id,
  ba.user_id AS broker_user_id,
  ba.broker,
  ba.platform
FROM terminal_sessions ts
JOIN broker_accounts ba
  ON ba.account_id = ts.broker_account_id
WHERE ts.status IN ('starting', 'running')
  AND ts.user_id IS DISTINCT FROM ba.user_id
ORDER BY ts.terminal_name;

-- Should return only user001 for Vantage/FTMO.
SELECT
  ba.broker,
  ba.platform,
  u.identity_slot,
  u.telegram_user_id,
  ts.terminal_name,
  ts.status
FROM broker_accounts ba
JOIN terminal_sessions ts
  ON ts.broker_account_id = ba.account_id
JOIN users u
  ON u.user_id = ba.user_id
WHERE ba.account_id IN (
  '95ad6253-1c4b-4c1a-b7fc-05941d76d550',
  '2200c898-5b23-4194-af12-b7ecf3aee68f'
)
ORDER BY ba.broker;
