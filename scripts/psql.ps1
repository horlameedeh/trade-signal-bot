$ErrorActionPreference = 'Stop'

$forwardedArgs = @($args)

$repoRoot = Split-Path -Parent $PSScriptRoot

if (-not $env:DATABASE_URL) {
    $dotenvPath = Join-Path $repoRoot '.env'
    if (Test-Path $dotenvPath) {
        foreach ($line in Get-Content $dotenvPath) {
            $trimmed = $line.Trim()
            if (-not $trimmed -or $trimmed.StartsWith('#')) {
                continue
            }

            $separatorIndex = $trimmed.IndexOf('=')
            if ($separatorIndex -lt 1) {
                continue
            }

            $name = $trimmed.Substring(0, $separatorIndex).Trim()
            $value = $trimmed.Substring($separatorIndex + 1).Trim()

            if (
                ($value.StartsWith('"') -and $value.EndsWith('"')) -or
                ($value.StartsWith("'") -and $value.EndsWith("'"))
            ) {
                $value = $value.Substring(1, $value.Length - 2)
            }

            if ($name -and -not [System.Environment]::GetEnvironmentVariable($name, 'Process')) {
                [System.Environment]::SetEnvironmentVariable($name, $value, 'Process')
            }
        }
    }
}

if (-not $env:DATABASE_URL) {
    throw 'DATABASE_URL is not set'
}

$psqlUrl = $env:DATABASE_URL -replace '\+psycopg2?', ''

function Invoke-PsqlCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Executable,

        [Parameter(Mandatory = $true)]
        [string[]]$CommandArgs
    )

    $output = & $Executable @CommandArgs
    $exitCode = $LASTEXITCODE

    if ($null -eq $output) {
        Write-Output ''
    }
    else {
        $output
    }

    exit $exitCode
}

$psqlCommand = Get-Command psql -ErrorAction SilentlyContinue
if ($psqlCommand) {
    $commandArgs = @($psqlUrl) + $forwardedArgs
    Invoke-PsqlCommand -Executable $psqlCommand.Source -CommandArgs $commandArgs
}

${dockerCommand} = Get-Command docker -ErrorAction SilentlyContinue
if (-not $dockerCommand) {
    throw 'psql is not installed or not on PATH, and docker is not available for fallback'
}

$commandArgs = @('compose', 'exec', '-T', 'postgres', 'psql', $psqlUrl) + $forwardedArgs
Invoke-PsqlCommand -Executable $dockerCommand.Source -CommandArgs $commandArgs