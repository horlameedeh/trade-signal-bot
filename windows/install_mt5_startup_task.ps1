param(
    [string]$TaskName = "TradeBotStartMT5",
    [string]$RepoPath = "C:\trade-signal-bot",
    [string]$WindowsUser,
    [switch]$AtStartup,
    [switch]$AtLogon
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not $AtStartup -and -not $AtLogon) {
    $AtLogon = $true
}

$scriptPath = Join-Path $RepoPath "windows\start_mt5_terminals.ps1"

if (!(Test-Path $scriptPath)) {
    throw "Launcher script not found: $scriptPath"
}

$action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-ExecutionPolicy Bypass -File `"$scriptPath`""

$triggers = @()
if ($AtStartup) {
    $triggers += New-ScheduledTaskTrigger -AtStartup
}
if ($AtLogon) {
    if ([string]::IsNullOrWhiteSpace($WindowsUser)) {
        $triggers += New-ScheduledTaskTrigger -AtLogOn
    } else {
        $triggers += New-ScheduledTaskTrigger -AtLogOn -User $WindowsUser
    }
}

$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable

if ([string]::IsNullOrWhiteSpace($WindowsUser)) {
    Register-ScheduledTask `
        -TaskName $TaskName `
        -Action $action `
        -Trigger $triggers `
        -Settings $settings `
        -Force | Out-Null
} else {
    Register-ScheduledTask `
        -TaskName $TaskName `
        -Action $action `
        -Trigger $triggers `
        -Settings $settings `
        -User $WindowsUser `
        -Force | Out-Null
}

Write-Host "Installed scheduled task: $TaskName"
