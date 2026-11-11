. (Join-Path $PSScriptRoot 'helpers.ps1')
$statePath = Join-Path $RuntimeRoot 'processes.json'
if (-not (Test-Path -LiteralPath $statePath)) { Write-Host 'This project has not been started.'; exit 0 }
$state = Get-Content -LiteralPath $statePath -Raw -Encoding UTF8 | ConvertFrom-Json
$jarPath = Join-Path $ProjectRoot 'backend\target\pet-community-0.1.0.jar'
if (Test-Owned-Process $state.appPid $jarPath) { Stop-Process -Id $state.appPid -ErrorAction Stop; Write-Host 'Project backend stopped.' }
$configPath = Join-Path $RuntimeRoot 'mysql\my.cnf'
if (Test-Owned-Process $state.mysqlPid $configPath) {
    $MySqlBin=Get-MySql-Bin; $AdminClient=Join-Path $RuntimeRoot 'mysql\admin-client.cnf'
    $actual=(Invoke-Project-Sql 'SELECT @@datadir;' $false | Out-String).Trim().TrimEnd('\','/')
    $expected=Join-Path $RuntimeRoot 'mysql\data'
    if ([IO.Path]::GetFullPath($actual) -ne [IO.Path]::GetFullPath($expected)) { throw 'Database directory mismatch; refusing to stop another instance.' }
    & (Join-Path $MySqlBin 'mysqladmin.exe') "--defaults-file=$AdminClient" shutdown
    if ($LASTEXITCODE -ne 0) { throw 'Could not gracefully stop the project database.' }
    Write-Host 'Project database stopped. Saved data remains in .runtime\mysql\data.'
}
