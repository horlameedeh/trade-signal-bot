param(
  [string]$RepoPath = "C:\trade-signal-bot"
)

Set-Location $RepoPath
. .\.venv\Scripts\Activate.ps1

$env:PYTHONPATH = $RepoPath
$env:PYTHONUTF8 = "1"
$env:PYTHONIOENCODING = "utf-8"

$logDir = Join-Path $RepoPath "logs"
$appLog = Join-Path $logDir "app.log"

New-Item -ItemType Directory -Path $logDir -Force | Out-Null
if (-not (Test-Path $appLog)) {
  New-Item -ItemType File -Path $appLog -Force | Out-Null
}

"[$(Get-Date -Format s)] starting telethon ingestion" | Out-File -FilePath $appLog -Append -Encoding utf8
python scripts\run_telethon_ingestion.py *>&1 | Tee-Object -FilePath $appLog -Append