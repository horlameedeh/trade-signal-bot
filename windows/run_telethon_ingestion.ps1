param(
  [string]$RepoPath = "C:\trade-signal-bot"
)

Set-Location $RepoPath
. .\.venv\Scripts\Activate.ps1

$env:PYTHONPATH = $RepoPath
$env:PYTHONUTF8 = "1"
$env:PYTHONIOENCODING = "utf-8"

python scripts\run_telethon_ingestion.py