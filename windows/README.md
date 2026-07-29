# TickerLens for Windows 11

Standalone **Windows 11 desktop app** — separate from the KDE Plasma widgets, same product goals:

- Frosted glass floating **Markets** + **News** panels  
- Looks close to the Plasma widgets (dark glass, badges, sparklines, sentiment)  
- System tray control  
- Free market data (Yahoo + earnings API); optional DeepSeek for news ratings  

This is **not** a Plasma build. It is a Qt 6 app designed for Win11 (also runs on Linux for development).

---

## Why this approach?

| Approach | Verdict |
|----------|---------|
| Plasma QML on Windows | Not practical |
| Share one QML plasmoid | Too many KDE-only APIs |
| **Dedicated Qt 6 desktop app** | Best balance: glass UI, one `.exe`, full control |
| Electron | Heavier, less “native widget” feel |

---

## Look & feel (Windows)

- Frameless translucent windows with soft shadow  
- **Windows 11 Acrylic / rounded corners** via DWM when available  
- Drag title bar · resize grip · always-on-top option  
- Tray icon: show/hide Markets or News, Quit  

---

## Build on Windows 11

### 1. Install tools
- [Visual Studio 2022](https://visualstudio.microsoft.com/) with **Desktop C++**  
- [Qt 6.5+](https://www.qt.io/download) (MSVC kit) + **Qt Quick**  
- [CMake](https://cmake.org/download/)  
- [Python 3](https://www.python.org/) (for optional AI ratings)  
- [Ninja](https://ninja-build.org/) (optional, recommended)

### 2. Build

```powershell
cd windows
.\build-windows.ps1 -QtPath "C:\Qt\6.7.3\msvc2019_64"
```

Output: `build\Release\TickerLens.exe` (plus Qt DLLs via `windeployqt`).

### 3. Run

Double-click **TickerLens.exe** or:

```powershell
.\build\Release\TickerLens.exe
```

Config lives in:

```text
%APPDATA%\TickerLens\TickerLens\
```

DeepSeek key (optional):

```text
%APPDATA%\TickerLens\TickerLens\deepseek.key
```

---

## Build on Linux (dev smoke test)

```bash
cd windows
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build -j
./build/TickerLens
```

---

## Feature map

| Feature | Windows app |
|---------|:-----------:|
| Live quotes, day change | ✓ |
| Sparklines (hide when narrow) | ✓ |
| ATH distance | ✓ |
| Next earnings | ✓ |
| Portfolio P/L | ✓ (JSON in settings) |
| Alerts (desktop toast on Win11) | ✓ |
| News + lexicon / DeepSeek | ✓ |
| Glass UI | ✓ |
| Tray | ✓ (replaces panel pill) |

---

## License

GNU GPL v3 — same as the main TickerLens repository.
