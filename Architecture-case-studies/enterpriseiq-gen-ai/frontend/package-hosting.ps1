$ErrorActionPreference = 'Stop'
Push-Location $PSScriptRoot
try {
    & npm.cmd run build
    if ($LASTEXITCODE -ne 0) { throw 'Frontend build failed.' }
    if (!(Test-Path -LiteralPath 'dist/index.html')) { throw 'Build output has no index.html.' }
    & python package_hosting.py
    if ($LASTEXITCODE -ne 0) { throw 'Frontend packaging failed.' }
} finally {
    Pop-Location
}
