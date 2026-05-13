-- 28B.4 / Windows only / terminal path standard gap audit
--
-- Purpose:
-- Compare current terminal_sessions paths against Milestone 28 directory standard.
--
-- Expected Windows terminal_path:
--   C:\Trading\Binaries\<BROKER_PLATFORM>\terminal64.exe
--
-- Expected Windows data_dir before real slot claim:
--   current admin sessions may still use legacy paths
--
-- Expected Windows data_dir after user001 claim:
--   C:\Trading\Data\user001\vantage-mt5
--   C:\Trading\Data\user001\ftmo-mt5

WITH expected AS (
    SELECT
      ts.session_id,
      ts.terminal_name,
      ts.terminal_path,
      ts.data_dir,
      ts.status,
      ba.broker::text AS broker,
      ba.platform::text AS platform,
      CASE
        WHEN ba.platform::text = 'mt5'
          THEN 'C:\Trading\Binaries\' ||
               initcap(ba.broker::text) ||
               '_MT5\terminal64.exe'
        WHEN ba.platform::text = 'mt4'
          THEN 'C:\Trading\Binaries\' ||
               initcap(ba.broker::text) ||
               '_MT4\terminal.exe'
        ELSE NULL
      END AS expected_terminal_path
    FROM terminal_sessions ts
    JOIN broker_accounts ba
      ON ba.account_id = ts.broker_account_id
)
SELECT
  session_id,
  terminal_name,
  broker,
  platform,
  status,
  terminal_path,
  expected_terminal_path,
  CASE
    WHEN terminal_path = expected_terminal_path THEN 'OK'
    ELSE 'PATH_STANDARD_GAP'
  END AS terminal_path_check,
  data_dir
FROM expected
ORDER BY terminal_name;
