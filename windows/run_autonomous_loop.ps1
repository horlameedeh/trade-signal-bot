param(
  [string]$RepoPath = "C:\trade-signal-bot",
  [string]$Broker = "ftmo",
  [string]$Platform = "mt5",
  [int]$IntervalSeconds = 30
)

Set-Location $RepoPath
. .\.venv\Scripts\Activate.ps1

$env:PYTHONPATH = $RepoPath
$env:PYTHONUTF8 = "1"
$env:PYTHONIOENCODING = "utf-8"

python scripts/run_autonomous_loop.py --broker $Broker --platform $Platform --interval-seconds $IntervalSeconds --run-recovery-first --monitor-every 20
