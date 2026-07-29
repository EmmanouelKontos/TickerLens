# Changelog

## 2.0.0

- Replaced the Windows Qt/QML frontend with an independent native WPF/.NET 8
  application rendered through DirectWrite and DirectX.
- Uses the real Windows 11 DWM Desktop Acrylic system backdrop, native rounded
  corners, native window shadows, and Windows typography.
- Added self-contained native Markets and News windows, live Yahoo quotes,
  sparklines, ATH distance, sentiment accents, settings, and tray controls.
- Windows no longer ships or loads Qt, QML, MinGW, or third-party UI runtimes.

## 1.7.2

- Redesigned the Windows Markets panel with a cleaner Fluent glass layout,
  larger typography, calmer spacing, modern stock cards, and subtle controls.
- Reduced the acrylic tint so the desktop blur remains clearly visible.
- Removed redundant window controls, heavy row separators, and the exposed
  scrollbar styling.

## 1.7.1

- Fixed the Windows package failing to start by rebuilding the executable with
  the same MinGW 13.1 C++ ABI used by the bundled Qt 6.7 runtime.
- Removed incompatible LLVM C++ runtime libraries from the Windows package.

## 1.7.0

- Reworked Windows glass rendering to use native Acrylic composition for
  frameless Qt windows, with Windows 11 DWM backdrop and legacy blur fallbacks.
- Reduced the surface tint so the frosted desktop blur remains visible.
- Preserved native Windows 11 rounded corners and DWM window shadows.
- Added a proper per-user Windows setup executable to GitHub releases.

## 1.6.6

- **Critical**: fix QML load failure (`onFlagsChanged` is invalid on Qt 6 Window — empty UI / reinstall dialog)
- Log QML warnings to tickerlens.log for easier diagnosis

## 1.6.5

- UI: real rounded corners (window region + larger radius), darker frosted panel
- Always-on-top **off by default**; no longer stuck above other apps
- Glass opacity + corner radius sliders apply **live**
- Check for updates button wired correctly via signals

## 1.6.4

- **Frosted glass**: Windows 11 acrylic blur + translucent tint (closer to KDE Plasma)
- **Tray-only**: widgets no longer appear on the taskbar (tool windows + WS_EX_TOOLWINDOW)
- **App icon**: unique TickerLens chart/lens icon for tray, exe, and installer

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
