SELECT
  broker,
  platform,
  COUNT(*) AS broker_rows,
  COUNT(*) FILTER (WHERE is_active = TRUE) AS active_rows,
  COUNT(*) FILTER (WHERE user_id IS NOT NULL) AS owned_rows,
  COUNT(*) FILTER (WHERE user_id IS NULL) AS unowned_rows
FROM broker_accounts
GROUP BY broker, platform
ORDER BY broker, platform;

SELECT
  account_id,
  broker,
  platform,
  kind,
  label,
  user_id,
  is_active,
  created_at,
  updated_at
FROM broker_accounts
WHERE lower(broker::text) IN ('vantage', 'ftmo', 'traderscale', 'fundednext', 'startrader', 'bullwaves')
ORDER BY broker, platform, is_active DESC, account_id;

SELECT
  account_id,
  broker,
  platform,
  kind,
  label,
  user_id,
  is_active
FROM broker_accounts
WHERE account_id IN (
  '95ad6253-1c4b-4c1a-b7fc-05941d76d550',
  '2200c898-5b23-4194-af12-b7ecf3aee68f',
  'b4701745-4244-4a7d-bae3-78e6594ff7fc',
  'b95ca62a-f2d5-4a24-86b6-1fe497c538ff',
  '357d66f3-cbb1-41bc-a8fa-163d2be75880',
  '043d8b63-4230-4121-a2d8-6e974b62ec15'
)
ORDER BY broker, platform;