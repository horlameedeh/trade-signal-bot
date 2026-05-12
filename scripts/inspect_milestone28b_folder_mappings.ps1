param(
    [string]$TradingRoot = "C:\Trading"
)

$ErrorActionPreference = "Stop"

$BinariesRoot = Join-Path $TradingRoot "Binaries"
$DataRoot = Join-Path $TradingRoot "Data"

$BrokerPlatforms = @(
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

$UserSlots = @("user001","user002","user003","user004","user005")
$UserBrokerDirs = @(
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

$ok = 0
$warn = 0
$err = 0
$warnings = New-Object System.Collections.Generic.List[string]
$errors = New-Object System.Collections.Generic.List[string]

function Add-Ok($msg) {
    $script:ok++
    Write-Host "[OK] $msg" -ForegroundColor Green
}

function Add-Warn($msg) {
    $script:warn++
    $script:warnings.Add($msg) | Out-Null
    Write-Host "[WARNING] $msg" -ForegroundColor Yellow
}

function Add-Err($msg) {
    $script:err++
    $script:errors.Add($msg) | Out-Null
    Write-Host "[ERROR] $msg" -ForegroundColor Red
}

Write-Host "=== Milestone 28B.1.a Windows Folder Mapping Inspection ==="
Write-Host "Root: $TradingRoot"
Write-Host ""

if (Test-Path $TradingRoot) { Add-Ok "Found trading root: $TradingRoot" } else { Add-Err "Missing trading root: $TradingRoot" }
if (Test-Path $BinariesRoot) { Add-Ok "Found binaries root: $BinariesRoot" } else { Add-Err "Missing binaries root: $BinariesRoot" }
if (Test-Path $DataRoot) { Add-Ok "Found data root: $DataRoot" } else { Add-Err "Missing data root: $DataRoot" }

Write-Host ""
Write-Host "--- Binary folder inspection ---"
foreach ($bp in $BrokerPlatforms) {
    $path = Join-Path $BinariesRoot $bp
    if (-not (Test-Path $path)) {
        Add-Warn "Missing binary folder: $path"
        continue
    }

    Add-Ok "Binary folder present: $path"

    $exes = Get-ChildItem -Path $path -Filter *.exe -File -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name
    if ($exes -and $exes.Count -gt 0) {
        Add-Ok "Executables found in $path => $($exes -join ', ')"
    } else {
        Add-Warn "No executables found in $path"
    }

    $terminalExe = Get-ChildItem -Path $path -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -in @("terminal.exe","terminal64.exe") } |
        Select-Object -First 1

    if ($terminalExe) {
        Add-Ok "Launchable terminal found: $($terminalExe.FullName)"
    } else {
        Add-Warn "No terminal.exe or terminal64.exe found in $path"
    }
}

Write-Host ""
Write-Host "--- Per-user data folder inspection ---"
foreach ($slot in $UserSlots) {
    $slotRoot = Join-Path $DataRoot $slot
    if (-not (Test-Path $slotRoot)) {
        Add-Warn "Missing user slot root: $slotRoot"
        continue
    }

    Add-Ok "User slot root present: $slotRoot"

    foreach ($dir in $UserBrokerDirs) {
        $path = Join-Path $slotRoot $dir
        if (Test-Path $path) {
            Add-Ok "Data folder present: $path"
        } else {
            Add-Warn "Missing data folder: $path"
        }
    }
}

Write-Host ""
Write-Host "--- Shared / suspicious mapping inspection ---"
$brokerToUsers = @{}
foreach ($slot in $UserSlots) {
    foreach ($dir in $UserBrokerDirs) {
        $path = Join-Path (Join-Path $DataRoot $slot) $dir
        if (Test-Path $path) {
            if (-not $brokerToUsers.ContainsKey($dir)) {
                $brokerToUsers[$dir] = New-Object System.Collections.Generic.List[string]
            }
            $brokerToUsers[$dir].Add($slot) | Out-Null
        }
    }
}

foreach ($dir in $brokerToUsers.Keys | Sort-Object) {
    $owners = $brokerToUsers[$dir]
    if ($owners.Count -gt 1) {
        Add-Ok "Pattern-B ready path set exists for $dir across slots => $($owners -join ', ')"
    } elseif ($owners.Count -eq 1) {
        Add-Warn "Only one slot currently has folder for $dir => $($owners -join ', ')"
    }
}

Write-Host ""
Write-Host "--- Legacy direct broker folders under C:\Trading ---"
$legacy = Get-ChildItem -Path $TradingRoot -Directory -ErrorAction SilentlyContinue |
    Where-Object {
        $_.Name -match '^(FTMO|Bullwaves|FundedNext|StarTrader|Traderscale|Vantage)_(MT4|MT5)$'
    }

if ($legacy) {
    foreach ($item in $legacy) {
        Add-Warn "Legacy broker folder still present under root: $($item.FullName)"
    }
} else {
    Add-Ok "No legacy broker folders directly under root"
}

Write-Host ""
Write-Host "--- Candidate terminal executable map ---"
$terminalMap = @()
foreach ($bp in $BrokerPlatforms) {
    $path = Join-Path $BinariesRoot $bp
    if (-not (Test-Path $path)) { continue }

    $terminalExe = Get-ChildItem -Path $path -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -in @("terminal.exe","terminal64.exe") } |
        Select-Object -First 1

    $terminalMap += [pscustomobject]@{
        BrokerPlatform = $bp
        BinaryFolder = $path
        TerminalExe = if ($terminalExe) { $terminalExe.FullName } else { $null }
    }
}

$terminalMap | Format-Table -AutoSize

Write-Host ""
Write-Host "=== Summary ==="
Write-Host "OK items: $ok"
Write-Host "Warnings: $warn"
Write-Host "Errors: $err"

if ($warnings.Count -gt 0) {
    Write-Host ""
    Write-Host "--- Warnings ---" -ForegroundColor Yellow
    $warnings | ForEach-Object { Write-Host $_ -ForegroundColor Yellow }
}

if ($errors.Count -gt 0) {
    Write-Host ""
    Write-Host "--- Errors ---" -ForegroundColor Red
    $errors | ForEach-Object { Write-Host $_ -ForegroundColor Red }
}

if ($err -eq 0) {
    Write-Host ""
    Write-Host "RESULT: Inspection completed. Review warnings before applying Pattern B ownership." -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "RESULT: Fix errors before continuing." -ForegroundColor Red
}
