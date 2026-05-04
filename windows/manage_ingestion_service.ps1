param(
    [ValidateSet("status", "start", "stop", "restart")]
    [string]$Action = "status",
    [string]$ServiceName = "TradeBot-Ingestion",
    [int]$Tail = 30
)

$ErrorActionPreference = "Stop"

function Test-IsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-NssmPath {
    $command = Get-Command nssm.exe -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }

    $fallback = "C:\ProgramData\chocolatey\bin\nssm.exe"
    if (Test-Path $fallback) {
        return $fallback
    }

    throw "nssm.exe was not found on PATH. Install NSSM or add it to PATH."
}

function Get-RepoPath {
    return Split-Path -Parent $PSScriptRoot
}

function Get-TelegramSessionPath {
    $repoPath = Get-RepoPath
    $envFile = Join-Path $repoPath ".env"
    $sessionName = "tradebot_ingestion"

    if (Test-Path $envFile) {
        $sessionLine = Get-Content $envFile | Where-Object { $_ -match '^TELEGRAM_USER_SESSION=' } | Select-Object -First 1
        if ($sessionLine) {
            $sessionName = ($sessionLine -split '=', 2)[1].Trim().Trim('"')
        }
    }

    return Join-Path $repoPath ("{0}.session" -f $sessionName)
}

function Assert-TelegramSessionPresent {
    $sessionPath = Get-TelegramSessionPath
    if (-not (Test-Path $sessionPath)) {
        throw "Telegram session file is missing at '$sessionPath'. Re-authenticate interactively with '.\\windows\\run_telethon_ingestion.ps1' or '.\\.venv\\Scripts\\python .\\scripts\\run_telethon_ingestion.py' before starting the service."
    }
}

function Show-Logs {
    $repoPath = Get-RepoPath
    $outLog = Join-Path $repoPath "logs\telethon_ingestion.out.log"
    $errLog = Join-Path $repoPath "logs\telethon_ingestion.err.log"

    Write-Host "stdout:" 
    if (Test-Path $outLog) {
        Get-Content $outLog -Tail $Tail
    }

    Write-Host "stderr:"
    if (Test-Path $errLog) {
        Get-Content $errLog -Tail $Tail
    }
}

$nssmPath = Get-NssmPath

if ($Action -in @("start", "restart")) {
    Assert-TelegramSessionPresent
}

if ($Action -ne "status" -and -not (Test-IsAdministrator)) {
    throw "Service action '$Action' requires an elevated PowerShell session. Reopen PowerShell as Administrator and rerun this script."
}

switch ($Action) {
    "status" {
        & $nssmPath status $ServiceName
        Show-Logs
    }
    "start" {
        & $nssmPath start $ServiceName
        & $nssmPath status $ServiceName
        Show-Logs
    }
    "stop" {
        & $nssmPath stop $ServiceName confirm
        & $nssmPath status $ServiceName
    }
    "restart" {
        & $nssmPath restart $ServiceName
        & $nssmPath status $ServiceName
        Show-Logs
    }
}