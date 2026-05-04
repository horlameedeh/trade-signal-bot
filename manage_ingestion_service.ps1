param(
    [ValidateSet("status", "start", "stop", "restart")]
    [string]$Action = "status",
    [string]$ServiceName = "TradeBot-Ingestion",
    [int]$Tail = 30
)

$scriptPath = Join-Path $PSScriptRoot "windows\manage_ingestion_service.ps1"

if (-not (Test-Path $scriptPath)) {
    throw "Expected helper script was not found at '$scriptPath'."
}

& $scriptPath -Action $Action -ServiceName $ServiceName -Tail $Tail