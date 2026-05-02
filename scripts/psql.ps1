param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Args
)

$ErrorActionPreference = 'Stop'

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

$psqlCommand = Get-Command psql -ErrorAction SilentlyContinue
if ($psqlCommand) {
    & $psqlCommand.Source $psqlUrl @Args
    exit $LASTEXITCODE
}

${dockerCommand} = Get-Command docker -ErrorAction SilentlyContinue
if (-not $dockerCommand) {
    throw 'psql is not installed or not on PATH, and docker is not available for fallback'
}

& $dockerCommand.Source compose exec -T postgres psql $psqlUrl @Args
exit $LASTEXITCODE