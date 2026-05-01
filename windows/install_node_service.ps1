param(
    [string]$ServiceName = "TradeBotExecutionNode",
    [string]$RepoPath = "C:\trade-signal-bot",
    [string]$NssmPath = "C:\ProgramData\chocolatey\lib\nssm\tools\nssm.exe"
)

$ErrorActionPreference = "Stop"

if (!(Test-Path $NssmPath)) {
    Write-Host "NSSM not found at: $NssmPath"
    Write-Host "Download NSSM and update -NssmPath."
    exit 1
}

$PowerShellExe = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
$ScriptPath = Join-Path $RepoPath "windows\run_node.ps1"

& $NssmPath install $ServiceName $PowerShellExe "-ExecutionPolicy Bypass -File `"$ScriptPath`" -RepoPath `"$RepoPath`""
& $NssmPath set $ServiceName AppDirectory $RepoPath
& $NssmPath set $ServiceName Start SERVICE_AUTO_START
& $NssmPath set $ServiceName AppStdout "$RepoPath\logs\execution_node.out.log"
& $NssmPath set $ServiceName AppStderr "$RepoPath\logs\execution_node.err.log"
& $NssmPath set $ServiceName AppRestartDelay 5000

Write-Host "Installed service: $ServiceName"
Write-Host "Start with:"
Write-Host "  Start-Service $ServiceName"
