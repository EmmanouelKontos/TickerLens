# TickerLens Windows installer (portable)
# Run from the extracted release folder:
#   Right-click -> Run with PowerShell
#   or: powershell -ExecutionPolicy Bypass -File .\Install-TickerLens.ps1
#
# Keep this file ASCII-only so Windows PowerShell 5.1 always parses it.

param(
    [string]$InstallDir = "$env:LOCALAPPDATA\TickerLens",
    [switch]$NoDesktopShortcut,
    [switch]$NoStartMenu
)

$ErrorActionPreference = "Stop"
$Here = Split-Path -Parent $MyInvocation.MyCommand.Path

# Support running from package root (next to TickerLens.exe) or packaging/
$Source = $Here
if (-not (Test-Path (Join-Path $Source "TickerLens.exe"))) {
    $parent = Split-Path -Parent $Here
    if (Test-Path (Join-Path $parent "TickerLens.exe")) {
        $Source = $parent
    }
}

$Exe = Join-Path $Source "TickerLens.exe"
if (-not (Test-Path $Exe)) {
    Write-Host "ERROR: TickerLens.exe not found next to this script." -ForegroundColor Red
    Write-Host "Extract the full release ZIP first, then run Install-TickerLens.ps1 from that folder."
    exit 1
}

Write-Host "Installing TickerLens to:" -ForegroundColor Cyan
Write-Host "  $InstallDir"
New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null

# Copy everything from the portable folder except installer noise
$exclude = @("Install-TickerLens.ps1", "Install.bat", "Uninstall.ps1")
Get-ChildItem -Path $Source -Force | Where-Object {
    $exclude -notcontains $_.Name
} | ForEach-Object {
    $dest = Join-Path $InstallDir $_.Name
    if ($_.PSIsContainer) {
        Copy-Item -Path $_.FullName -Destination $dest -Recurse -Force
    } else {
        Copy-Item -Path $_.FullName -Destination $dest -Force
    }
}

# Ensure helper script is present
$rateSrc = Join-Path $Source "rate_news.py"
if (Test-Path $rateSrc) {
    Copy-Item $rateSrc (Join-Path $InstallDir "rate_news.py") -Force
}

$InstalledExe = Join-Path $InstallDir "TickerLens.exe"

# Start Menu shortcut
if (-not $NoStartMenu) {
    $startDir = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs"
    New-Item -ItemType Directory -Force -Path $startDir | Out-Null
    $lnk = Join-Path $startDir "TickerLens.lnk"
    $w = New-Object -ComObject WScript.Shell
    $s = $w.CreateShortcut($lnk)
    $s.TargetPath = $InstalledExe
    $s.WorkingDirectory = $InstallDir
    $s.Description = "TickerLens markets and news for Windows"
    $s.Save()
    Write-Host "Start Menu shortcut created."
}

# Desktop shortcut
if (-not $NoDesktopShortcut) {
    $desk = [Environment]::GetFolderPath("Desktop")
    $lnk = Join-Path $desk "TickerLens.lnk"
    $w = New-Object -ComObject WScript.Shell
    $s = $w.CreateShortcut($lnk)
    $s.TargetPath = $InstalledExe
    $s.WorkingDirectory = $InstallDir
    $s.Description = "TickerLens"
    $s.Save()
    Write-Host "Desktop shortcut created."
}

# Uninstaller helper (ASCII-only)
$un = @"
`$dir = "$InstallDir"
Remove-Item -LiteralPath (Join-Path `$env:APPDATA "Microsoft\Windows\Start Menu\Programs\TickerLens.lnk") -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath (Join-Path ([Environment]::GetFolderPath('Desktop')) "TickerLens.lnk") -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath `$dir -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "TickerLens removed."
"@
# Windows PowerShell 5.1: UTF8 without BOM can break; use Unicode (UTF-16 LE) for the helper
Set-Content -Path (Join-Path $InstallDir "Uninstall.ps1") -Value $un -Encoding Unicode

Write-Host ""
Write-Host "Installed successfully." -ForegroundColor Green
Write-Host "Launching TickerLens..."
Start-Process -FilePath $InstalledExe -WorkingDirectory $InstallDir
