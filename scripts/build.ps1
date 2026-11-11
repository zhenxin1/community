param([string]$MavenRepository = '', [string]$NpmCache = '')
. (Join-Path $PSScriptRoot 'helpers.ps1')
if (Test-Path -LiteralPath (Join-Path $RuntimeRoot 'processes.json')) { & (Join-Path $PSScriptRoot 'stop.ps1') }
$javaPath = Find-Java
$env:JAVA_HOME = Split-Path -Parent (Split-Path -Parent $javaPath)
$cacheRoot = Join-Path $ProjectRoot '.cache'
New-Item -ItemType Directory -Path $cacheRoot -Force | Out-Null
if (-not $MavenRepository) { $MavenRepository = Join-Path $cacheRoot 'maven' }
if (-not $NpmCache) { $NpmCache = Join-Path $cacheRoot 'npm' }
$npmPath = (Get-Command npm.cmd -ErrorAction Stop).Source
$mavenPath = (Get-Command mvn.cmd -ErrorAction Stop).Source
Push-Location (Join-Path $ProjectRoot 'frontend')
try {
    $ErrorActionPreference='Continue'
    Write-Host 'Installing locked frontend dependencies...'
    & $npmPath ci --registry=https://registry.npmjs.org --cache $NpmCache --no-fund --no-audit
    if ($LASTEXITCODE -ne 0) { throw 'npm ci failed. Node.js 20.19+ / 22.12+ is required.' }
    & $npmPath run build
    if ($LASTEXITCODE -ne 0) { throw 'Frontend build failed.' }
} finally { $ErrorActionPreference='Stop'; Pop-Location }
Push-Location (Join-Path $ProjectRoot 'backend')
try {
    $ErrorActionPreference='Continue'
    Write-Host 'Building backend and running unit tests...'
    & $mavenPath -B -ntp "-Dmaven.repo.local=$MavenRepository" clean package
    if ($LASTEXITCODE -ne 0) { throw 'Backend build failed.' }
} finally { $ErrorActionPreference='Stop'; Pop-Location }
Write-Host 'Build complete. Run scripts\start.ps1 to start the project.'
