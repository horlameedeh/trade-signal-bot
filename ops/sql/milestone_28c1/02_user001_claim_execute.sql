-- 28C.1 / execute user001 claim and ownership migration
--
-- Claimant Telegram user ID:
--   103751272
--
-- Windows production only.
-- Run only after:
-- - DB snapshot
-- - 01_user001_claim_dry_run.sql reviewed
--
-- This script:
-- - claims user001
-- - assigns canonical Vantage MT5 and FTMO MT5 broker rows to user001
-- - renames and reassigns the existing Vantage/FTMO terminal sessions
-- - updates terminal paths and data dirs to Milestone 28 standard

BEGIN;

-- 1) Hard stop if Telegram ID is already assigned to a different user.
DO $$
DECLARE
    existing_user_id uuid;
    slot_user_id uuid;
BEGIN
    SELECT user_id INTO existing_user_id
    FROM users
    WHERE telegram_user_id = 103751272;

    SELECT user_id INTO slot_user_id
    FROM users
    WHERE identity_slot = 'user001';

    IF slot_user_id IS NULL THEN
        RAISE EXCEPTION 'user001 slot does not exist';
    END IF;

    IF existing_user_id IS NOT NULL AND existing_user_id <> slot_user_id THEN
        RAISE EXCEPTION 'telegram_user_id 103751272 is already assigned to another user: %', existing_user_id;
    END IF;
END $$;

-- 2) Claim user001.
UPDATE users
SET
  telegram_user_id = 103751272,
  display_name = COALESCE(NULLIF(display_name, ''), 'TradeSignal User 001'),
  is_active = TRUE,
  updated_at = now()
WHERE identity_slot = 'user001';

-- 3) Assign canonical Vantage/FTMO broker rows to user001.
WITH slot_user AS (
    SELECT user_id
    FROM users
    WHERE identity_slot = 'user001'
)
UPDATE broker_accounts ba
SET
  user_id = su.user_id,
  is_active = TRUE,
  updated_at = now()
FROM slot_user su
WHERE ba.account_id IN (
  '95ad6253-1c4b-4c1a-b7fc-05941d76d550',
  '2200c898-5b23-4194-af12-b7ecf3aee68f'
);

-- 4) Reassign and standardize Vantage terminal session.
WITH slot_user AS (
    SELECT user_id
    FROM users
    WHERE identity_slot = 'user001'
)
UPDATE terminal_sessions ts
SET
  user_id = su.user_id,
  terminal_name = 'prod-vantage-mt5-user001',
  terminal_path = 'C:\Trading\Binaries\Vantage_MT5\terminal64.exe',
  data_dir = 'C:\Trading\Data\user001\vantage-mt5',
  updated_at = now()
FROM slot_user su
WHERE ts.broker_account_id = '95ad6253-1c4b-4c1a-b7fc-05941d76d550';

-- 5) Reassign and standardize FTMO terminal session.
WITH slot_user AS (
    SELECT user_id
    FROM users
    WHERE identity_slot = 'user001'
)
UPDATE terminal_sessions ts
SET
  user_id = su.user_id,
  terminal_name = 'prod-ftmo-mt5-user001',
  terminal_path = 'C:\Trading\Binaries\FTMO_MT5\terminal64.exe',
  data_dir = 'C:\Trading\Data\user001\ftmo-mt5',
  updated_at = now()
FROM slot_user su
WHERE ts.broker_account_id = '2200c898-5b23-4194-af12-b7ecf3aee68f';

-- 6) Verify user001 claim.
SELECT
  user_id,
  telegram_user_id,
  display_name,
  role,
  identity_slot,
  is_active
FROM users
WHERE identity_slot = 'user001';

-- 7) Verify Vantage/FTMO broker ownership.
SELECT
  account_id,
  broker,
  platform,
  label,
  user_id,
  is_active
FROM broker_accounts
WHERE account_id IN (
  '95ad6253-1c4b-4c1a-b7fc-05941d76d550',
  '2200c898-5b23-4194-af12-b7ecf3aee68f'
)
ORDER BY broker;

-- 8) Verify Vantage/FTMO terminal ownership and paths.
SELECT
  ts.session_id,
  ts.terminal_name,
  ts.terminal_path,
  ts.data_dir,
  ts.status,
  ts.user_id AS terminal_user_id,
  ba.user_id AS broker_user_id,
  ba.broker,
  ba.platform
FROM terminal_sessions ts
JOIN broker_accounts ba
  ON ba.account_id = ts.broker_account_id
WHERE ts.broker_account_id IN (
  '95ad6253-1c4b-4c1a-b7fc-05941d76d550',
  '2200c898-5b23-4194-af12-b7ecf3aee68f'
)
ORDER BY ba.broker;

-- 9) Hard stop if owner mismatch exists for active/running sessions.
DO $$
DECLARE
    mismatch_count integer;
BEGIN
    SELECT COUNT(*) INTO mismatch_count
    FROM terminal_sessions ts
    JOIN broker_accounts ba
      ON ba.account_id = ts.broker_account_id
    WHERE ts.status IN ('starting', 'running')
      AND ts.user_id IS DISTINCT FROM ba.user_id;

    IF mismatch_count > 0 THEN
        RAISE EXCEPTION 'terminal/broker owner mismatch count after user001 claim: %', mismatch_count;
    END IF;
END $$;

COMMIT;
