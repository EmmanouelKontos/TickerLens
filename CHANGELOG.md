# Changelog

## 1.6.3

- **Windows windows not showing**: tray worked but Markets/News never appeared — fixed show/hide via Win32 bring-to-front, solid window base, no binding fights
- **Single instance**: second launch activates the existing app instead of starting another process

## 1.6.2

- **Critical Windows fix**: app entry point called CRT `main` instead of Qt `qMain` (window never started)
- Startup log at `%LOCALAPPDATA%\TickerLens\tickerlens.log` and error dialog if UI fails to load
- Always show Markets window on launch if both windows were hidden

## 1.6.1

- **Windows fix**: rebuild with MinGW GCC / libstdc++ matching Qt (llvm/libc++ ABI mismatch crashed on start)
- **Installer fix**: PowerShell script is ASCII-only (broken by em-dash encoding on Windows PowerShell 5.1)
- **Windows setup.exe**: NSIS installer (`TickerLens-windows-x64-*-setup.exe`) installs to `%LOCALAPPDATA%\TickerLens`, Start Menu + Desktop shortcuts, uninstaller

## 1.6.0

- **Check for updates** (Windows + Plasma): polls GitHub Releases once per day when enabled
- Popup + desktop notification with **Install & restart** / **Install now**, open release page, Later, or Skip this version
- **Auto install** (user confirms): Windows downloads zip, applies into install folder, restarts; Plasma downloads tarball and runs `install.sh`
- Settings toggle: **Check for updates** (on by default); Windows also has **Check now**

## 1.5.0

- Product name: **TickerLens** (+ **TickerLens News**)
- Remove dead UI files (`FullView.qml`, `StockRow.qml`)
- Security: hardened DeepSeek helper, gitignore secrets, SECURITY.md
- Docs: full README for the suite
- **Windows 11 desktop port** (`windows/`): Qt 6 dual glass windows, tray, same market/news features

## 1.4.x

- Next earnings dates (stockanalysis.com)
- Companion news widget + shared watchlist file
- Free lexicon sentiment + optional DeepSeek AI ratings

## 1.3.x

- Portfolio P/L, alerts, multi-column, sparklines, day range
- Power/holiday pause, ATH cache, export watchlist

## 1.2.x

- Batch Yahoo spark quotes, ATH queue, sparklines

## 1.1.x – 1.0.x

- Initial Plasma 6 glass watchlist, desktop representation fixes
