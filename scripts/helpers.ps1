$ErrorActionPreference = 'Stop'
$OutputEncoding = New-Object System.Text.UTF8Encoding($false)
[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)
$ProjectRoot = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$RuntimeRoot = Join-Path $ProjectRoot '.runtime'

function Find-Java {
    if ($env:JAVA_HOME -and (Test-Path -LiteralPath (Join-Path $env:JAVA_HOME 'bin\java.exe'))) {
        $javaPath = Join-Path $env:JAVA_HOME 'bin\java.exe'
    } else {
        $javaPath = (Get-Command java.exe -ErrorAction Stop).Source
    }
    $probeInfo = New-Object Diagnostics.ProcessStartInfo
    $probeInfo.FileName=$javaPath; $probeInfo.Arguments='-version'
    $probeInfo.UseShellExecute=$false; $probeInfo.CreateNoWindow=$true
    $probeInfo.RedirectStandardError=$true; $probeInfo.RedirectStandardOutput=$true
    $probeProcess=New-Object Diagnostics.Process; $probeProcess.StartInfo=$probeInfo
    [void]$probeProcess.Start()
    $versionText=$probeProcess.StandardError.ReadToEnd()+$probeProcess.StandardOutput.ReadToEnd()
    $probeProcess.WaitForExit(); $probeProcess.Dispose()
    if ($versionText -notmatch 'version "(\d+)') { throw 'Cannot detect Java version. Set JAVA_HOME to a JDK 17 or newer.' }
    if ([int]$Matches[1] -lt 17) { throw 'Java 17+ is required. Set JAVA_HOME to your newer JDK; Java 8 cannot run this project.' }
    return $javaPath
}
function Quote-Argument([string]$value) { return '"' + $value + '"' }
function Write-Utf8([string]$path, [string]$value) { [IO.File]::WriteAllText($path, $value, (New-Object Text.UTF8Encoding($false))) }
function Ensure-Port-Free([int]$port) {
    $listener = New-Object Net.Sockets.TcpListener([Net.IPAddress]::Loopback, $port)
    try { $listener.Start() } catch { throw "Port $port is already in use. Use -AppPort / -DatabasePort to choose a free port." }
    finally { $listener.Stop() }
}
function Test-Owned-Process($processId, [string]$marker) {
    if (-not $processId) { return $false }
    $processInfo = Get-CimInstance Win32_Process -Filter "ProcessId = $processId" -ErrorAction SilentlyContinue
    return ($null -ne $processInfo -and $processInfo.CommandLine -and $processInfo.CommandLine.IndexOf($marker, [StringComparison]::OrdinalIgnoreCase) -ge 0)
}
function Get-MySql-Bin {
    if ($env:MYSQL_HOME -and (Test-Path -LiteralPath (Join-Path $env:MYSQL_HOME 'bin\mysqld.exe'))) { return Join-Path $env:MYSQL_HOME 'bin' }
    return Split-Path -Parent (Get-Command mysqld.exe -ErrorAction Stop).Source
}
function Test-MySql-Connection {
    $probeInfo=New-Object Diagnostics.ProcessStartInfo
    $probeInfo.FileName=Join-Path $MySqlBin 'mysql.exe'
    $probeInfo.Arguments='--defaults-file='+(Quote-Argument $AdminClient)+' --batch --skip-column-names'
    $probeInfo.UseShellExecute=$false; $probeInfo.CreateNoWindow=$true
    $probeInfo.RedirectStandardInput=$true; $probeInfo.RedirectStandardOutput=$true; $probeInfo.RedirectStandardError=$true
    $probeProcess=New-Object Diagnostics.Process; $probeProcess.StartInfo=$probeInfo
    [void]$probeProcess.Start(); $probeProcess.StandardInput.WriteLine('SELECT 1;'); $probeProcess.StandardInput.Close()
    [void]$probeProcess.StandardOutput.ReadToEnd(); [void]$probeProcess.StandardError.ReadToEnd()
    $probeProcess.WaitForExit(); $success=($probeProcess.ExitCode -eq 0); $probeProcess.Dispose()
    return $success
}
function Invoke-Project-Sql([string]$sql, [bool]$selectDatabase = $true) {
    $clientArgs = @("--defaults-file=$AdminClient", '--default-character-set=utf8mb4', '--batch', '--skip-column-names')
    if ($selectDatabase) { $clientArgs += '--database=pet_community' }
    $result = $sql | & (Join-Path $MySqlBin 'mysql.exe') @clientArgs
    if ($LASTEXITCODE -ne 0) { throw 'The project database command failed. See the MySQL output above.' }
    return $result
}
