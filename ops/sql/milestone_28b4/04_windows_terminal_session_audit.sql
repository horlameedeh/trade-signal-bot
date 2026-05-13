SELECT
  ts.session_id,
  ts.terminal_name,
  ts.terminal_path,
  ts.data_dir,
  ts.status,
  ts.user_id AS terminal_user_id,
  ts.broker_account_id,
  ba.broker,
  ba.platform,
  ba.label,
  ba.user_id AS broker_user_id,
  ba.is_active AS broker_active
FROM terminal_sessions ts
JOIN broker_accounts ba
  ON ba.account_id = ts.broker_account_id
ORDER BY ts.terminal_name;

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
WHERE ts.user_id IS DISTINCT FROM ba.user_id
ORDER BY ts.terminal_name NULLS LAST, ts.session_id;

SELECT
  ts.session_id,
  ts.terminal_name,
  ts.broker_account_id,
  ba.broker,
  ba.platform,
  ba.is_active
FROM terminal_sessions ts
JOIN broker_accounts ba
  ON ba.account_id = ts.broker_account_id
WHERE ts.status IN ('starting', 'running')
  AND ba.account_id NOT IN (
    '95ad6253-1c4b-4c1a-b7fc-05941d76d550',
    '2200c898-5b23-4194-af12-b7ecf3aee68f',
    'b4701745-4244-4a7d-bae3-78e6594ff7fc',
    'b95ca62a-f2d5-4a24-86b6-1fe497c538ff',
    '357d66f3-cbb1-41bc-a8fa-163d2be75880',
    '043d8b63-4230-4121-a2d8-6e974b62ec15'
  )
ORDER BY ts.terminal_name;