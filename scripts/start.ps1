$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$app=Join-Path $root 'PetAdoptionCommunity'
$configPath=Join-Path $root '.local\runtime.json'
if(!(Test-Path -LiteralPath $configPath)){throw 'Run python scripts/manage.py configure and init first; see README.'}
$config=Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
$env:DB_URL=$config.DB_URL
$env:DB_USERNAME=$config.DB_USERNAME
$env:DB_PASSWORD=$config.DB_PASSWORD
if($env:JAVA_HOME){$java=Join-Path $env:JAVA_HOME 'bin\java.exe'}
elseif(Test-Path -LiteralPath 'D:\Program Files\Java 17 for MC\jdk-17\bin\java.exe'){$java='D:\Program Files\Java 17 for MC\jdk-17\bin\java.exe'}
else{$java=(Get-Command java -ErrorAction Stop).Source}
$jar=Join-Path $app 'target\PetAdoptionCommunity-0.0.1-SNAPSHOT.jar'
if(!(Test-Path -LiteralPath $jar)){throw 'Build first with scripts/build.ps1'}
Write-Host 'Starting Pet Haven: http://127.0.0.1:8080/ ; Ctrl+C stops this process.'
Push-Location $app
try { & $java -jar $jar } finally { Pop-Location }
