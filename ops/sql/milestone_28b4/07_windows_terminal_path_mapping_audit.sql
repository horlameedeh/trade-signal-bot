-- 28B.4 / Windows only / explicit terminal path mapping audit
--
-- This is the authoritative path mapping audit.
-- It does not update anything.

WITH path_map AS (
    SELECT *
    FROM (
        VALUES
          ('vantage',     'mt5', 'C:\Trading\Binaries\Vantage_MT5\terminal64.exe'),
          ('ftmo',        'mt5', 'C:\Trading\Binaries\FTMO_MT5\terminal64.exe'),
          ('traderscale', 'mt5', 'C:\Trading\Binaries\Traderscale_MT5\terminal64.exe'),
          ('fundednext',  'mt5', 'C:\Trading\Binaries\FundedNext_MT5\terminal64.exe'),
          ('startrader',  'mt5', 'C:\Trading\Binaries\StarTrader_MT5\terminal64.exe'),
          ('bullwaves',   'mt5', 'C:\Trading\Binaries\Bullwaves_MT5\terminal64.exe')
    ) AS t(broker, platform, expected_terminal_path)
)
SELECT
  ts.session_id,
  ts.terminal_name,
  ba.broker,
  ba.platform,
  ts.status,
  ts.terminal_path,
  pm.expected_terminal_path,
  CASE
    WHEN ts.terminal_path = pm.expected_terminal_path THEN 'OK'
    ELSE 'PATH_STANDARD_GAP'
  END AS terminal_path_check,
  ts.data_dir
FROM terminal_sessions ts
JOIN broker_accounts ba
  ON ba.account_id = ts.broker_account_id
LEFT JOIN path_map pm
  ON pm.broker = lower(ba.broker::text)
 AND pm.platform = lower(ba.platform::text)
ORDER BY ts.terminal_name;
