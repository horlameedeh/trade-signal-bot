-- 28B.4 / Windows only / canonical broker inventory freeze
--
-- Purpose:
-- - Keep exactly one canonical active broker_accounts row per broker/platform.
-- - Force all duplicate non-canonical rows inactive.
-- - Preserve historical duplicate rows.
-- - Do not delete anything.
--
-- IMPORTANT:
-- Run on Windows production DB only after a DB snapshot is taken.

BEGIN;

-- 1) Confirm canonical rows exist before making changes.
WITH expected(account_id, broker, platform) AS (
    VALUES
      ('95ad6253-1c4b-4c1a-b7fc-05941d76d550'::uuid, 'vantage', 'mt5'),
      ('2200c898-5b23-4194-af12-b7ecf3aee68f'::uuid, 'ftmo', 'mt5'),
      ('b4701745-4244-4a7d-bae3-78e6594ff7fc'::uuid, 'traderscale', 'mt5'),
      ('b95ca62a-f2d5-4a24-86b6-1fe497c538ff'::uuid, 'fundednext', 'mt5'),
      ('357d66f3-cbb1-41bc-a8fa-163d2be75880'::uuid, 'startrader', 'mt5'),
      ('043d8b63-4230-4121-a2d8-6e974b62ec15'::uuid, 'bullwaves', 'mt5')
),
missing AS (
    SELECT e.*
    FROM expected e
    LEFT JOIN broker_accounts ba
      ON ba.account_id = e.account_id
    WHERE ba.account_id IS NULL
)
SELECT
  CASE
    WHEN COUNT(*) = 0 THEN 'OK: all canonical rows exist'
    ELSE 'ERROR: missing canonical rows'
  END AS canonical_row_check,
  COUNT(*) AS missing_count
FROM missing;

-- 2) Re-assert canonical rows active.
UPDATE broker_accounts
SET
  is_active = TRUE,
  updated_at = now()
WHERE account_id IN (
  '95ad6253-1c4b-4c1a-b7fc-05941d76d550',
  '2200c898-5b23-4194-af12-b7ecf3aee68f',
  'b4701745-4244-4a7d-bae3-78e6594ff7fc',
  'b95ca62a-f2d5-4a24-86b6-1fe497c538ff',
  '357d66f3-cbb1-41bc-a8fa-163d2be75880',
  '043d8b63-4230-4121-a2d8-6e974b62ec15'
);

-- 3) Force duplicate non-canonical rows inactive.
UPDATE broker_accounts
SET
  is_active = FALSE,
  updated_at = now()
WHERE lower(broker::text) IN (
    'vantage',
    'ftmo',
    'traderscale',
    'fundednext',
    'startrader',
    'bullwaves'
)
AND lower(platform::text) = 'mt5'
AND account_id NOT IN (
  '95ad6253-1c4b-4c1a-b7fc-05941d76d550',
  '2200c898-5b23-4194-af12-b7ecf3aee68f',
  'b4701745-4244-4a7d-bae3-78e6594ff7fc',
  'b95ca62a-f2d5-4a24-86b6-1fe497c538ff',
  '357d66f3-cbb1-41bc-a8fa-163d2be75880',
  '043d8b63-4230-4121-a2d8-6e974b62ec15'
);

-- 4) Verify exactly one active row per broker/platform.
SELECT
  broker,
  platform,
  COUNT(*) AS broker_rows,
  COUNT(*) FILTER (WHERE is_active = TRUE) AS active_rows,
  COUNT(*) FILTER (WHERE user_id IS NOT NULL) AS owned_rows,
  COUNT(*) FILTER (WHERE user_id IS NULL) AS unowned_rows
FROM broker_accounts
WHERE lower(broker::text) IN (
    'vantage',
    'ftmo',
    'traderscale',
    'fundednext',
    'startrader',
    'bullwaves'
)
AND lower(platform::text) = 'mt5'
GROUP BY broker, platform
ORDER BY broker, platform;

-- 5) Verify no running/starting session points to a non-canonical broker row.
SELECT
  ts.session_id,
  ts.terminal_name,
  ts.status,
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

COMMIT;
