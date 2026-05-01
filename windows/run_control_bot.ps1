param(
  [string]$RepoPath = "C:\trade-signal-bot"
)

Set-Location $RepoPath
.\.venv\Scripts\Activate.ps1

$env:PYTHONPATH = $RepoPath

python -m app.telegram.control_bot