param(
    [string]$RepoPath = "C:\trade-signal-bot",
    [string]$EnvFile = "C:\trade-signal-bot\windows\.env"
)

$ErrorActionPreference = "Stop"

Write-Host "Starting TradeBot execution node..."
Write-Host "RepoPath: $RepoPath"
Write-Host "EnvFile:  $EnvFile"

Set-Location $RepoPath

if (Test-Path $EnvFile) {
    Get-Content $EnvFile | ForEach-Object {
        if ($_ -match "^\s*$") { return }
        if ($_ -match "^\s*#") { return }

        $parts = $_ -split "=", 2
        if ($parts.Length -eq 2) {
            [Environment]::SetEnvironmentVariable($parts[0].Trim(), $parts[1].Trim(), "Process")
        }
    }
}

$hostName = $env:TRADEBOT_NODE_HOST
if ([string]::IsNullOrWhiteSpace($hostName)) {
    $hostName = "0.0.0.0"
}

$port = $env:TRADEBOT_NODE_PORT
if ([string]::IsNullOrWhiteSpace($port)) {
    $port = "8008"
}

if (Test-Path ".\.venv\Scripts\Activate.ps1") {
    . .\.venv\Scripts\Activate.ps1
}

python -m uvicorn app.execution.node_stub:app --host $hostName --port $port
