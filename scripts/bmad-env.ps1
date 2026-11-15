# Dot-source this file from a terminal before starting the coding agent.
$bmadProjectRoot = Split-Path -Parent $PSScriptRoot
$bmadUvBin = Join-Path $bmadProjectRoot '.local\bmad-tools\bin'
if (-not (Test-Path -LiteralPath (Join-Path $bmadUvBin 'uv.exe'))) {
    throw 'uv is missing. See docs/bmad-installation.md for installation instructions.'
}
$env:PATH = "$bmadUvBin;$env:PATH"
$env:UV_CACHE_DIR = Join-Path $bmadProjectRoot '.local\uv-cache'
Write-Host 'BMAD local tools enabled for this terminal.'
uv --version
