param([int]$AppPort = 18080, [int]$DatabasePort = 33079)
. (Join-Path $PSScriptRoot 'helpers.ps1')
$javaPath = Find-Java
$jarPath = Join-Path $ProjectRoot 'backend\target\pet-community-0.1.0.jar'
if (-not (Test-Path -LiteralPath $jarPath)) { & (Join-Path $PSScriptRoot 'build.ps1') }
New-Item -ItemType Directory -Path $RuntimeRoot -Force | Out-Null
$settingsPath = Join-Path $RuntimeRoot 'dev-settings.json'
$processPath = Join-Path $RuntimeRoot 'processes.json'
$mysqlRoot = Join-Path $RuntimeRoot 'mysql'
$dataPath = Join-Path $mysqlRoot 'data'
$mysqlConfig = Join-Path $mysqlRoot 'my.cnf'
$AdminClient = Join-Path $mysqlRoot 'admin-client.cnf'
$MySqlBin = Get-MySql-Bin
$oldState = $null
if (Test-Path -LiteralPath $processPath) { $oldState = Get-Content -LiteralPath $processPath -Raw -Encoding UTF8 | ConvertFrom-Json }
if (Test-Path -LiteralPath $settingsPath) {
    $settings = Get-Content -LiteralPath $settingsPath -Raw -Encoding UTF8 | ConvertFrom-Json
    if (-not $PSBoundParameters.ContainsKey('AppPort')) { $AppPort = [int]$settings.appPort }
    if (-not $PSBoundParameters.ContainsKey('DatabasePort')) { $DatabasePort = [int]$settings.databasePort }
} else {
    $settings = [PSCustomObject]@{ appPort=$AppPort; databasePort=$DatabasePort; rootPassword=([guid]::NewGuid().ToString('N')+[guid]::NewGuid().ToString('N')); appPassword=([guid]::NewGuid().ToString('N')+[guid]::NewGuid().ToString('N')) }
}
if ((Test-Owned-Process $oldState.appPid $jarPath) -and (Test-Owned-Process $oldState.mysqlPid $mysqlConfig)) {
    Write-Host "Already running: http://127.0.0.1:$($oldState.appPort)/login"
    exit 0
}
if (Test-Owned-Process $oldState.appPid $jarPath) { Stop-Process -Id $oldState.appPid -ErrorAction Stop }
if ((Test-Owned-Process $oldState.mysqlPid $mysqlConfig) -and [int]$oldState.databasePort -ne $DatabasePort) {
    throw 'Stop this project before changing its database port.'
}
$settings.appPort=$AppPort; $settings.databasePort=$DatabasePort
Write-Utf8 $settingsPath ($settings | ConvertTo-Json)
New-Item -ItemType Directory -Path $mysqlRoot -Force | Out-Null
$mysqlProcessId = $oldState.mysqlPid
if (-not (Test-Owned-Process $mysqlProcessId $mysqlConfig)) {
    Ensure-Port-Free $DatabasePort
    $mysqlBase = Split-Path -Parent $MySqlBin
    if (-not (Test-Path -LiteralPath (Join-Path $dataPath 'auto.cnf'))) {
        Write-Host 'Initializing a separate, persistent project MySQL data directory...'
        & (Join-Path $MySqlBin 'mysqld.exe') --no-defaults --initialize-insecure "--basedir=$($mysqlBase.Replace('\','/'))" "--datadir=$($dataPath.Replace('\','/'))" "--log-error=$((Join-Path $mysqlRoot 'initialize.log').Replace('\','/'))"
        if ($LASTEXITCODE -ne 0) { throw 'MySQL initialization failed. See .runtime\mysql\initialize.log.' }
    }
    $mysqlText = @"
[mysqld]
basedir="$($mysqlBase.Replace('\','/'))"
datadir="$($dataPath.Replace('\','/'))"
port=$DatabasePort
bind-address=127.0.0.1
mysqlx=OFF
skip-log-bin
innodb-buffer-pool-size=64M
log-error="$((Join-Path $mysqlRoot 'server.log').Replace('\','/'))"
"@
    Write-Utf8 $mysqlConfig $mysqlText
    $mysqlProcess = Start-Process -FilePath (Join-Path $MySqlBin 'mysqld.exe') -ArgumentList @('--defaults-file='+(Quote-Argument $mysqlConfig)) -WorkingDirectory $ProjectRoot -WindowStyle Hidden -PassThru
    $mysqlProcessId = $mysqlProcess.Id
}
Write-Utf8 $processPath (@{ appPid=$null; mysqlPid=$mysqlProcessId; appPort=$AppPort; databasePort=$DatabasePort } | ConvertTo-Json)
function Write-Admin-Client([string]$password) {
    Write-Utf8 $AdminClient "[client]`nhost=127.0.0.1`nport=$DatabasePort`nprotocol=TCP`nuser=root`npassword=$password`n"
}
Write-Admin-Client $settings.rootPassword
$connected = $false
for ($attempt=0; $attempt -lt 60; $attempt++) {
    if (Test-MySql-Connection) { $connected=$true; break }
    Start-Sleep -Milliseconds 250
    if (-not (Get-Process -Id $mysqlProcessId -ErrorAction SilentlyContinue)) { throw 'Project MySQL exited. See .runtime\mysql\server.log.' }
    if ($attempt -eq 6) {
        Write-Admin-Client ''
        if (Test-MySql-Connection) {
            "ALTER USER 'root'@'localhost' IDENTIFIED BY '$($settings.rootPassword)';" | & (Join-Path $MySqlBin 'mysql.exe') "--defaults-file=$AdminClient"
            if ($LASTEXITCODE -ne 0) { throw 'Could not configure the project database credential.' }
        }
        Write-Admin-Client $settings.rootPassword
    }
}
if (-not $connected) { throw 'Could not connect to the separate project MySQL. See .runtime\mysql\server.log.' }
$actualData = (Invoke-Project-Sql 'SELECT @@datadir;' $false | Out-String).Trim().TrimEnd('\','/')
if ([IO.Path]::GetFullPath($actualData) -ne [IO.Path]::GetFullPath($dataPath)) { throw 'Database directory mismatch; refusing to modify another instance.' }
Invoke-Project-Sql "CREATE DATABASE IF NOT EXISTS pet_community CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;" $false | Out-Null
$hasUserTable = Invoke-Project-Sql "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='pet_community' AND table_name='sys_user';" $false
if ([int]$hasUserTable -eq 0) {
    Write-Host 'Creating the complete 25-table project database...'
    Invoke-Project-Sql (Get-Content -LiteralPath (Join-Path $ProjectRoot 'database\mysql\01-schema.sql') -Raw -Encoding UTF8) | Out-Null
    Invoke-Project-Sql (Get-Content -LiteralPath (Join-Path $ProjectRoot 'database\mysql\02-seed.sql') -Raw -Encoding UTF8) | Out-Null
}

$legacyRoleCount = Invoke-Project-Sql "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema=DATABASE() AND table_name IN ('sys_role','sys_permission','sys_user_role','sys_role_permission');"
$roleColumnCount = Invoke-Project-Sql "SELECT COUNT(*) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='sys_user' AND column_name='role';"
if ([int]$legacyRoleCount -gt 0 -or [int]$roleColumnCount -eq 0) {
    $backupRoot = Join-Path $RuntimeRoot 'backups'
    New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null
    $backupPath = Join-Path $backupRoot ('before-simplification-' + (Get-Date -Format 'yyyyMMdd-HHmmss-fff') + '.sql')
    & (Join-Path $MySqlBin 'mysqldump.exe') "--defaults-file=$AdminClient" --single-transaction --set-gtid-purged=OFF --no-tablespaces "--result-file=$backupPath" pet_community
    if ($LASTEXITCODE -ne 0) { throw 'Database backup failed; migration was not started.' }
    Write-Host 'Backup complete. Upgrading the account tables...'
    Invoke-Project-Sql (Get-Content -LiteralPath (Join-Path $ProjectRoot 'database\mysql\migrations\001-simplify-accounts.sql') -Raw -Encoding UTF8) | Out-Null
}


# Complete an existing two-table account database without recreating those tables.
$businessTableNames = @('adoption_application','adoption_appointment','adoption_complaint','adoption_conversation','adoption_message','adoption_need','adoption_pet','api_idempotency','community_category','community_comment','community_like','community_post','community_report','operation_log','shop_cart_item','shop_category','shop_order','shop_order_item','shop_product','shop_refund','user_address','user_favorite','user_notice')
$businessNameSql = ($businessTableNames | ForEach-Object { "'" + $_ + "'" }) -join ','
$businessTableCount = [int](Invoke-Project-Sql "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema=DATABASE() AND table_name IN ($businessNameSql);")
if ($businessTableCount -eq 0) {
    $backupRoot = Join-Path $RuntimeRoot 'backups'
    New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null
    $backupPath = Join-Path $backupRoot ('before-complete-schema-' + (Get-Date -Format 'yyyyMMdd-HHmmss-fff') + '.sql')
    & (Join-Path $MySqlBin 'mysqldump.exe') "--defaults-file=$AdminClient" --single-transaction --set-gtid-purged=OFF --no-tablespaces "--result-file=$backupPath" pet_community
    if ($LASTEXITCODE -ne 0) { throw 'Database backup failed; no business tables were created.' }
    Write-Host 'Adding the remaining 23 business tables; existing accounts are preserved...'
    Invoke-Project-Sql (Get-Content -LiteralPath (Join-Path $ProjectRoot 'database\mysql\migrations\002-add-business-tables.sql') -Raw -Encoding UTF8) | Out-Null
    Invoke-Project-Sql (Get-Content -LiteralPath (Join-Path $ProjectRoot 'database\mysql\02-seed.sql') -Raw -Encoding UTF8) | Out-Null
} elseif ($businessTableCount -ne $businessTableNames.Count) {
    throw 'The database has a partial business schema. Restore/review the backup before retrying; existing tables will not be overwritten.'
}

Invoke-Project-Sql "CREATE USER IF NOT EXISTS 'pet_app'@'localhost' IDENTIFIED BY '$($settings.appPassword)'; GRANT SELECT,INSERT,UPDATE,DELETE ON pet_community.* TO 'pet_app'@'localhost';" $false | Out-Null
Ensure-Port-Free $AppPort
$envNames = @('APP_PORT','DB_URL','DB_USERNAME','DB_PASSWORD','APP_STORAGE_ROOT')
$previousEnv = @{}
foreach ($envName in $envNames) { $previousEnv[$envName]=[Environment]::GetEnvironmentVariable($envName,'Process') }
try {
    $env:APP_PORT=[string]$AppPort
    $env:DB_URL="jdbc:mysql://127.0.0.1:$DatabasePort/pet_community?connectionTimeZone=UTC&forceConnectionTimeZoneToSession=true&characterEncoding=UTF-8"
    $env:DB_USERNAME='pet_app'; $env:DB_PASSWORD=$settings.appPassword
    $env:APP_STORAGE_ROOT=Join-Path $ProjectRoot 'storage\uploads'
    $appProcess=Start-Process -FilePath $javaPath -ArgumentList @('-Dfile.encoding=UTF-8','-jar',(Quote-Argument $jarPath)) -WorkingDirectory $ProjectRoot -WindowStyle Hidden -RedirectStandardOutput (Join-Path $RuntimeRoot 'backend.log') -RedirectStandardError (Join-Path $RuntimeRoot 'backend-error.log') -PassThru
} finally {
    foreach ($envName in $envNames) { [Environment]::SetEnvironmentVariable($envName,$previousEnv[$envName],'Process') }
}
Write-Utf8 $processPath (@{ appPid=$appProcess.Id; mysqlPid=$mysqlProcessId; appPort=$AppPort; databasePort=$DatabasePort } | ConvertTo-Json)
for ($attempt=0; $attempt -lt 80; $attempt++) {
    if (-not (Get-Process -Id $appProcess.Id -ErrorAction SilentlyContinue)) { throw 'Backend exited. See .runtime\backend.log and backend-error.log.' }
    try {
        $response=Invoke-WebRequest -Uri "http://127.0.0.1:$AppPort/api/v1/common/session" -UseBasicParsing -TimeoutSec 2
        if ($response.StatusCode -eq 200) { Write-Host "Ready: http://127.0.0.1:$AppPort/login"; exit 0 }
    } catch { Start-Sleep -Milliseconds 500 }
}
throw 'Backend did not become ready. See .runtime\backend.log.'
