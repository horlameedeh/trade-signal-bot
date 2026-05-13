SELECT
  user_id,
  telegram_user_id,
  display_name,
  role,
  identity_slot,
  is_active
FROM users
ORDER BY
  CASE WHEN telegram_user_id = 7622982526 THEN 0 ELSE 1 END,
  identity_slot NULLS LAST,
  display_name NULLS LAST;

SELECT identity_slot, COUNT(*) AS row_count
FROM users
WHERE identity_slot IS NOT NULL
GROUP BY identity_slot
HAVING COUNT(*) > 1
ORDER BY identity_slot;

SELECT telegram_user_id, COUNT(*) AS row_count
FROM users
WHERE telegram_user_id IS NOT NULL
GROUP BY telegram_user_id
HAVING COUNT(*) > 1
ORDER BY telegram_user_id;

SELECT
  identity_slot,
  display_name,
  telegram_user_id,
  role,
  is_active
FROM users
WHERE identity_slot IN ('user001','user002','user003','user004','user005')
ORDER BY identity_slot;