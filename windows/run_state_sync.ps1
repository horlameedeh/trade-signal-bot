param(
  [string]$RepoPath = "C:\trade-signal-bot"
)

Set-Location $RepoPath
.\.venv\Scripts\Activate.ps1

$env:PYTHONPATH = $RepoPath

while ($true) {
  python scripts/sync_execution_state.py --broker ftmo --platform mt5
  Start-Sleep -Seconds 15
}