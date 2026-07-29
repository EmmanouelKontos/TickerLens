@echo off
title TickerLens Setup
cd /d "%~dp0"
echo.
echo  TickerLens for Windows 11
echo  -------------------------
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install-TickerLens.ps1"
if errorlevel 1 (
  echo.
  echo Setup failed. You can still run TickerLens.exe from this folder.
  pause
)
