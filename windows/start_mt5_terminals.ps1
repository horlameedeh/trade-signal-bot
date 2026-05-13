param(
    [string]$ConfigPath = "C:\trade-signal-bot\windows\mt5-terminals.json",
    [int]$LaunchDelaySeconds = 10
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (!(Test-Path $ConfigPath)) {
    throw "MT5 config not found at $ConfigPath"
}

$config = Get-Content $ConfigPath -Raw | ConvertFrom-Json

if ($null -eq $config.terminals -or $config.terminals.Count -eq 0) {
    throw "No terminals defined in $ConfigPath"
}

foreach ($terminal in $config.terminals) {
    if ([string]::IsNullOrWhiteSpace($terminal.name)) {
        throw "Each terminal entry must define a name"
    }

    if ([string]::IsNullOrWhiteSpace($terminal.path)) {
        throw "Terminal '$($terminal.name)' is missing path"
    }

    if (!(Test-Path $terminal.path)) {
        throw "Terminal '$($terminal.name)' path not found: $($terminal.path)"
    }

    $arguments = @()

    if ($terminal.portable -eq $true) {
        $arguments += "/portable"
    }

    if (-not [string]::IsNullOrWhiteSpace($terminal.profile)) {
        $arguments += "/profile:$($terminal.profile)"
    }

    if (-not [string]::IsNullOrWhiteSpace($terminal.config)) {
        $arguments += "/config:$($terminal.config)"
    }

    $workingDirectory = Split-Path -Path $terminal.path -Parent

    Write-Host "Starting MT5 terminal '$($terminal.name)' from $($terminal.path)"
    Start-Process -FilePath $terminal.path -ArgumentList $arguments -WorkingDirectory $workingDirectory | Out-Null
}
