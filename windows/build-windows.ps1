# Build TickerLens for Windows 11
# Usage:
#   .\build-windows.ps1
#   .\build-windows.ps1 -QtPath "C:\Qt\6.7.3\msvc2019_64"

param(
    [string]$QtPath = $env:CMAKE_PREFIX_PATH,
    [string]$Generator = "Ninja",
    [string]$Config = "Release"
)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

if (-not $QtPath) {
    Write-Host "Set -QtPath or CMAKE_PREFIX_PATH to your Qt 6 kit (e.g. C:\Qt\6.7.3\msvc2019_64)" -ForegroundColor Yellow
    exit 1
}

Write-Host "Configuring with Qt at $QtPath ..."
cmake -B build -DCMAKE_PREFIX_PATH="$QtPath" -DCMAKE_BUILD_TYPE=$Config -G $Generator
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "Building..."
cmake --build build --config $Config
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$outDir = if (Test-Path "build\$Config") { "build\$Config" } else { "build" }
$exe = Join-Path $outDir "TickerLens.exe"

$windeploy = Join-Path $QtPath "bin\windeployqt.exe"
if (Test-Path $windeploy) {
    Write-Host "Deploying Qt runtime..."
    & $windeploy --qmldir "$PSScriptRoot\qml" $exe
}

Copy-Item -Force "$PSScriptRoot\scripts\rate_news.py" $outDir

Write-Host ""
Write-Host "Done: $exe" -ForegroundColor Green
Write-Host "Run TickerLens.exe — use the tray icon to manage windows."
