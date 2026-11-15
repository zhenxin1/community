$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$app=Join-Path $root 'PetAdoptionCommunity'
Push-Location (Join-Path $app 'vue1')
try { & npm.cmd ci --no-audit --no-fund; if($LASTEXITCODE -ne 0){throw 'npm ci failed'}; & npm.cmd run build; if($LASTEXITCODE -ne 0){throw 'Vue build failed'} } finally { Pop-Location }
$static=Join-Path $app 'src\main\resources\static'
New-Item -ItemType Directory -Force -Path $static | Out-Null
Copy-Item -Path (Join-Path $app 'vue1\dist\*') -Destination $static -Recurse -Force
Push-Location $app
try { & .\mvnw.cmd package; if($LASTEXITCODE -ne 0){throw 'Backend build failed'}; & .\mvnw.cmd dependency:build-classpath '-Dmdep.outputFile=target/classpath.txt'; if($LASTEXITCODE -ne 0){throw 'Classpath generation failed'} } finally { Pop-Location }
Write-Host 'Built one Spring Boot jar containing Vue assets. Run python scripts/manage.py init, then serve.'
