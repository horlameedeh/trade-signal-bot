-- 28C.3 / verify provider fallback route safety

SELECT
  par.provider_code,
  par.route_priority,
  par.route_role,
  par.broker_account_id,
  par.is_active AS route_active,
  ba.broker,
  ba.platform,
  ba.label,
  ba.user_id AS broker_user_id,
  u.identity_slot,
  u.telegram_user_id,
  ts.terminal_name,
  ts.user_id AS terminal_user_id,
  ts.status AS terminal_status,
  CASE
    WHEN par.is_active IS NOT TRUE THEN 'INACTIVE_ROUTE'
    WHEN ba.is_active IS NOT TRUE THEN 'INACTIVE_BROKER'
    WHEN ts.session_id IS NULL THEN 'NO_TERMINAL_SESSION'
    WHEN ts.status NOT IN ('starting', 'running') THEN 'TERMINAL_NOT_RUNNING'
    WHEN ba.user_id IS DISTINCT FROM ts.user_id THEN 'OWNER_MISMATCH'
    ELSE 'OK'
  END AS route_execution_check
FROM provider_account_routes par
JOIN broker_accounts ba
  ON ba.account_id = par.broker_account_id
LEFT JOIN users u
  ON u.user_id = ba.user_id
LEFT JOIN terminal_sessions ts
  ON ts.broker_account_id = ba.account_id
WHERE par.is_active = TRUE
ORDER BY par.provider_code, par.route_priority, ba.broker, ba.platform;

-- Should return 0 rows.
SELECT
  par.provider_code,
  par.route_priority,
  COUNT(*) AS active_routes_at_priority
FROM provider_account_routes par
WHERE par.is_active = TRUE
GROUP BY par.provider_code, par.route_priority
HAVING COUNT(*) > 1
ORDER BY par.provider_code, par.route_priority;

-- Should return 0 rows.
SELECT
  par.provider_code,
  ba.broker,
  ba.platform,
  par.broker_account_id,
  ba.is_active AS broker_active
FROM provider_account_routes par
JOIN broker_accounts ba
  ON ba.account_id = par.broker_account_id
WHERE par.is_active = TRUE
  AND ba.is_active IS NOT TRUE
ORDER BY par.provider_code, ba.broker, ba.platform;
