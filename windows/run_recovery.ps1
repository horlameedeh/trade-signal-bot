param(
  [string]$RepoPath = "C:\trade-signal-bot"
)

Set-Location $RepoPath
.\.venv\Scripts\Activate.ps1

$env:PYTHONPATH = $RepoPath

python scripts/recover_after_restart.py --broker ftmo --platform mt5