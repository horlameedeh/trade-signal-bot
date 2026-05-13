$BinariesRoot = 'C:\Trading\Binaries'
$DataRoot = 'C:\Trading\Data'

Write-Host "=== BINARIES ROOT ==="
if (Test-Path $BinariesRoot) {
    Get-ChildItem -Path $BinariesRoot -Directory |
        Sort-Object Name |
        Select-Object Name, FullName
} else {
    Write-Host "Missing binaries root: $BinariesRoot"
}

Write-Host "`n=== EXPECTED BINARY FOLDERS / TERMINAL EXE CHECK ==="

$expected = @(
    'FTMO_MT4',
    'FTMO_MT5',
    'Bullwaves_MT4',
    'Bullwaves_MT5',
    'FundedNext_MT4',
    'FundedNext_MT5',
    'StarTrader_MT4',
    'StarTrader_MT5',
    'Traderscale_MT4',
    'Traderscale_MT5',
    'Vantage_MT4',
    'Vantage_MT5'
)

foreach ($folder in $expected) {
    $path = Join-Path $BinariesRoot $folder
    $exists = Test-Path $path

    $terminalExe = $null
    $anyExe = $null

    if ($exists) {
        $terminalExe = Get-ChildItem -Path $path -Recurse -File -Include terminal.exe,terminal64.exe -ErrorAction SilentlyContinue |
            Select-Object -First 1

        $anyExe = Get-ChildItem -Path $path -Recurse -File -Include *.exe -ErrorAction SilentlyContinue |
            Select-Object -First 1
    }

    [PSCustomObject]@{
        BrokerPlatform  = $folder
        FolderExists    = $exists
        TerminalExeFound = [bool]($terminalExe)
        TerminalExePath = if ($terminalExe) { $terminalExe.FullName } else { $null }
        AnyExeFound     = [bool]($anyExe)
        ExampleAnyExe   = if ($anyExe) { $anyExe.FullName } else { $null }
    }
}

Write-Host "`n=== DATA ROOT ==="
if (Test-Path $DataRoot) {
    Get-ChildItem -Path $DataRoot -Directory |
        Sort-Object Name |
        Select-Object Name, FullName
} else {
    Write-Host "Missing data root: $DataRoot"
}

Write-Host "`n=== SLOT DIRECTORY CHECK ==="
$slots = @('admin','user001','user002','user003','user004','user005')

foreach ($slot in $slots) {
    $slotPath = Join-Path $DataRoot $slot
    [PSCustomObject]@{
        Slot         = $slot
        FolderExists = Test-Path $slotPath
        FullPath     = $slotPath
    }
}

Write-Host "`n=== PER-SLOT BROKER/PLATFORM DATA DIRECTORY CHECK ==="
$claimSlots = @('user001','user002','user003','user004','user005')

$brokerPlatformDirs = @(
    'ftmo-mt4',
    'ftmo-mt5',
    'bullwaves-mt4',
    'bullwaves-mt5',
    'fundednext-mt4',
    'fundednext-mt5',
    'startrader-mt4',
    'startrader-mt5',
    'traderscale-mt4',
    'traderscale-mt5',
    'vantage-mt4',
    'vantage-mt5'
)

foreach ($slot in $claimSlots) {
    foreach ($bp in $brokerPlatformDirs) {
        $p = Join-Path (Join-Path $DataRoot $slot) $bp
        [PSCustomObject]@{
            Slot           = $slot
            BrokerPlatform = $bp
            FolderExists   = Test-Path $p
            FullPath       = $p
        }
    }
}