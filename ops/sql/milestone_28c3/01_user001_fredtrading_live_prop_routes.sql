-- 28C.3 / user001 fredtrading live + prop fallback routes
--
-- Requires migration:
-- - provider_account_routes.route_priority
-- - provider_account_routes.route_role
-- - no single-active-provider unique constraint
--
-- Target:
-- - fredtrading -> Vantage MT5 primary_live, priority 10
-- - fredtrading -> FTMO MT5 fallback_prop, priority 20

BEGIN;

-- Deactivate stale fredtrading routes.
UPDATE provider_account_routes
SET is_active = FALSE
WHERE provider_code = 'fredtrading';

-- Insert Vantage route if missing.
INSERT INTO provider_account_routes (
  provider_code,
  broker_account_id,
  is_active,
  route_priority,
  route_role
)
SELECT
  'fredtrading',
  '95ad6253-1c4b-4c1a-b7fc-05941d76d550'::uuid,
  TRUE,
  10,
  'primary_live'
WHERE NOT EXISTS (
  SELECT 1
  FROM provider_account_routes
  WHERE provider_code = 'fredtrading'
    AND broker_account_id = '95ad6253-1c4b-4c1a-b7fc-05941d76d550'::uuid
);

-- Update Vantage route.
UPDATE provider_account_routes
SET
  is_active = TRUE,
  route_priority = 10,
  route_role = 'primary_live'
WHERE provider_code = 'fredtrading'
  AND broker_account_id = '95ad6253-1c4b-4c1a-b7fc-05941d76d550'::uuid;

-- Insert FTMO route if missing.
INSERT INTO provider_account_routes (
  provider_code,
  broker_account_id,
  is_active,
  route_priority,
  route_role
)
SELECT
  'fredtrading',
  '2200c898-5b23-4194-af12-b7ecf3aee68f'::uuid,
  TRUE,
  20,
  'fallback_prop'
WHERE NOT EXISTS (
  SELECT 1
  FROM provider_account_routes
  WHERE provider_code = 'fredtrading'
    AND broker_account_id = '2200c898-5b23-4194-af12-b7ecf3aee68f'::uuid
);

-- Update FTMO route.
UPDATE provider_account_routes
SET
  is_active = TRUE,
  route_priority = 20,
  route_role = 'fallback_prop'
WHERE provider_code = 'fredtrading'
  AND broker_account_id = '2200c898-5b23-4194-af12-b7ecf3aee68f'::uuid;

COMMIT;
