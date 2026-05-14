-- 28C.3 / inspect provider_account_routes constraints and columns

SELECT
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'provider_account_routes'
ORDER BY ordinal_position;

SELECT
  conname,
  contype,
  pg_get_constraintdef(c.oid) AS definition
FROM pg_constraint c
JOIN pg_class t
  ON t.oid = c.conrelid
JOIN pg_namespace n
  ON n.oid = t.relnamespace
WHERE n.nspname = 'public'
  AND t.relname = 'provider_account_routes'
ORDER BY conname;

SELECT
  indexname,
  indexdef
FROM pg_indexes
WHERE schemaname = 'public'
  AND tablename = 'provider_account_routes'
ORDER BY indexname;
