param(
  [string]$RepoPath = "C:\trade-signal-bot",
  [string]$Broker = "ftmo",
  [string]$Platform = "mt5"
)

Set-Location $RepoPath
. .\.venv\Scripts\Activate.ps1

$env:PYTHONPATH = $RepoPath
$env:PYTHONUTF8 = "1"
$env:PYTHONIOENCODING = "utf-8"

python scripts/recover_after_restart.py --broker $Broker --platform $Platform