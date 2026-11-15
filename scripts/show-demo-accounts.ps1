$path=Join-Path (Split-Path $PSScriptRoot -Parent) '.local\demo-credentials.json'
if(!(Test-Path -LiteralPath $path)){throw 'Run initialization first'}
Write-Host 'Local classroom demo credentials. Do not record or commit this output.'
$data=Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
$data.PSObject.Properties | ForEach-Object { Write-Host ($_.Name+': '+$_.Value.account+' / '+$_.Value.password) }
