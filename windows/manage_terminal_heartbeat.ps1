param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("once", "loop", "stop")]
    [string]$Action,

    [Parameter(Mandatory=$true)]
    [string]$SessionId,

    [string]$RepoPath = "C:\trade-signal-bot",

    [int]$IntervalSeconds = 30
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Set-Location $RepoPath
$python = Join-Path $RepoPath ".venv\Scripts\python.exe"

if (!(Test-Path $python)) {
    throw "Python venv not found at $python"
}

$env:PYTHONPATH = $RepoPath

if ($Action -eq "once") {
    & $python ".\scripts\terminal_heartbeat.py" --session-id $SessionId --once
    exit $LASTEXITCODE
}

if ($Action -eq "loop") {
    & $python ".\scripts\terminal_heartbeat.py" --session-id $SessionId --interval-seconds $IntervalSeconds
    exit $LASTEXITCODE
}

if ($Action -eq "stop") {
    & $python ".\scripts\terminal_heartbeat.py" --session-id $SessionId --mark-stopped
    exit $LASTEXITCODE
}
