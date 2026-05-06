param(
    [string]$Root = "C:\Trading"
)

$ErrorActionPreference = "Stop"

$binariesRoot = Join-Path $Root "Binaries"
$dataRoot = Join-Path $Root "Data"

$expectedBinaryDirs = @(
    "FTMO_MT4",
    "FTMO_MT5",
    "Bullwaves_MT4",
    "Bullwaves_MT5",
    "FundedNext_MT4",
    "FundedNext_MT5",
    "StarTrader_MT4",
    "StarTrader_MT5",
    "Traderscale_MT4",
    "Traderscale_MT5",
    "Vantage_MT4",
    "Vantage_MT5"
)

$userSlots = @("user001", "user002", "user003", "user004", "user005")

$expectedDataDirs = @(
    "ftmo-mt4",
    "ftmo-mt5",
    "bullwaves-mt4",
    "bullwaves-mt5",
    "fundednext-mt4",
    "fundednext-mt5",
    "startrader-mt4",
    "startrader-mt5",
    "traderscale-mt4",
    "traderscale-mt5",
    "vantage-mt4",
    "vantage-mt5"
)

$legacyBrokerDirs = @(
    "FTMO_MT4",
    "FTMO_MT5",
    "Bullwaves_MT4",
    "Bullwaves_MT5",
    "FundedNext_MT4",
    "FundedNext_MT5",
    "StarTrader_MT4",
    "StarTrader_MT5",
    "Traderscale_MT4",
    "Traderscale_MT5",
    "Vantage_MT4",
    "Vantage_MT5"
)

$errors = New-Object System.Collections.Generic.List[string]
$warnings = New-Object System.Collections.Generic.List[string]
$oks = New-Object System.Collections.Generic.List[string]

function Add-Ok([string]$Message) {
    $oks.Add($Message) | Out-Null
    Write-Host "[OK] $Message"
}

function Add-Warning([string]$Message) {
    $warnings.Add($Message) | Out-Null
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Add-Error([string]$Message) {
    $errors.Add($Message) | Out-Null
    Write-Host "[MISSING] $Message" -ForegroundColor Red
}

Write-Host "=== Milestone 28A.1 Layout Inspection ==="
Write-Host "Root: $Root"
Write-Host ""

if (Test-Path $Root) {
    Add-Ok "Found root folder: $Root"
} else {
    Add-Error "Missing root folder: $Root"
}

if (Test-Path $binariesRoot) {
    Add-Ok "Found binaries root: $binariesRoot"
} else {
    Add-Error "Missing binaries root: $binariesRoot"
}

if (Test-Path $dataRoot) {
    Add-Ok "Found data root: $dataRoot"
} else {
    Add-Error "Missing data root: $dataRoot"
}

Write-Host ""
Write-Host "--- Checking binary folders ---"
foreach ($dir in $expectedBinaryDirs) {
    $path = Join-Path $binariesRoot $dir
    if (Test-Path $path) {
        Add-Ok "Binary folder present: $path"
    } else {
        Add-Error "Binary folder missing: $path"
    }
}

Write-Host ""
Write-Host "--- Checking per-user data folders ---"
foreach ($user in $userSlots) {
    foreach ($dir in $expectedDataDirs) {
        $path = Join-Path (Join-Path $dataRoot $user) $dir
        if (Test-Path $path) {
            Add-Ok "Data folder present: $path"
        } else {
            Add-Error "Data folder missing: $path"
        }
    }
}

Write-Host ""
Write-Host "--- Checking for legacy broker folders directly under root ---"
foreach ($dir in $legacyBrokerDirs) {
    $legacyPath = Join-Path $Root $dir
    if (Test-Path $legacyPath) {
        Add-Warning "Legacy broker folder still at root: $legacyPath"
    }
}

Write-Host ""
Write-Host "--- Checking executables inside binary folders ---"
foreach ($dir in $expectedBinaryDirs) {
    $path = Join-Path $binariesRoot $dir
    if (Test-Path $path) {
        $executables = Get-ChildItem -Path $path -Filter "*.exe" -File -ErrorAction SilentlyContinue
        if ($executables -and $executables.Count -gt 0) {
            $names = ($executables | Select-Object -ExpandProperty Name) -join ", "
            Add-Ok "Executables found in $path => $names"
        } else {
            Add-Warning "No .exe files found in $path"
        }
    }
}

Write-Host ""
Write-Host "=== Summary ==="
Write-Host "OK items: $($oks.Count)"
Write-Host "Warnings: $($warnings.Count)"
Write-Host "Errors: $($errors.Count)"
Write-Host ""

if ($warnings.Count -gt 0) {
    Write-Host "--- Warnings ---" -ForegroundColor Yellow
    $warnings | ForEach-Object { Write-Host $_ -ForegroundColor Yellow }
    Write-Host ""
}

if ($errors.Count -gt 0) {
    Write-Host "--- Errors ---" -ForegroundColor Red
    $errors | ForEach-Object { Write-Host $_ -ForegroundColor Red }
    Write-Host ""
    Write-Host "RESULT: NOT YET ALIGNED with Milestone 28A.1" -ForegroundColor Red
    exit 1
}

Write-Host "RESULT: Layout aligns with Milestone 28A.1" -ForegroundColor Green
exit 0