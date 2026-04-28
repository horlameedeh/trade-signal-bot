param(
    [string]$Url = "http://127.0.0.1:8008/health"
)

$ErrorActionPreference = "Stop"

try {
    $response = Invoke-RestMethod -Uri $Url -Method GET -TimeoutSec 5
    if ($response.ok -eq $true) {
        Write-Host "OK - TradeBot execution node healthy"
        Write-Host ($response | ConvertTo-Json -Depth 5)
        exit 0
    }

    Write-Host "NOT OK - health endpoint returned ok=false"
    Write-Host ($response | ConvertTo-Json -Depth 5)
    exit 1
}
catch {
    Write-Host "ERROR - health check failed"
    Write-Host $_.Exception.Message
    exit 1
}
