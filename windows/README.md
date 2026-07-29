# TickerLens for Windows 11

Desktop port of [TickerLens](https://github.com/EmmanouelKontos/TickerLens) with the same features as the Plasma widgets:

- **Markets** floating glass window (quotes, ATH, earnings, sparklines, portfolio, alerts)
- **News** floating glass window (headlines + lexicon / DeepSeek sentiment)
- System tray to show/hide either window
- Settings dialogs, always-on-top option
- Shared watchlist under app config dir

Plugin IDs on Linux Plasma are unchanged; this is a **second product line** in `windows/`.

---

## Requirements (build)

- **CMake** ≥ 3.21  
- **Qt 6.5+** with modules: Core, Gui, Qml, Quick, QuickControls2, Network, Widgets  
- **C++17** compiler (MSVC 2019+, MinGW, or Clang)  
- **Python 3** on PATH (only for optional DeepSeek ratings)

### Windows install (Qt)

1. Install [Qt Online Installer](https://www.qt.io/download) → Qt 6.x for MSVC or MinGW + Qt Quick.  
2. Install CMake and a compiler (Visual Studio Build Tools recommended).  
3. Open “x64 Native Tools Command Prompt for VS” or set `CMAKE_PREFIX_PATH` to your Qt kit, e.g.  
   `C:\Qt\6.7.0\msvc2019_64`

---

## Build

### Windows (PowerShell)

```powershell
cd windows
.\build-windows.ps1
```

Or manually:

```powershell
cd windows
cmake -B build -DCMAKE_PREFIX_PATH="C:\Qt\6.7.3\msvc2019_64" -G "Ninja"
cmake --build build --config Release
# Deploy Qt DLLs:
windeployqt build\Release\TickerLens.exe
copy scripts\rate_news.py build\Release\
```

### Linux (dev / CI smoke)

```bash
cd windows
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build -j
./build/TickerLens
```

---

## Run

```text
TickerLens.exe
```

- Drag windows by the frosted background  
- **↻** refresh · **⚙** settings · **✕** hide window  
- Tray icon → show/hide Markets or News · Quit  
- Config: `%APPDATA%\TickerLens\TickerLens\` (Windows) or `~/.config/TickerLens/` (Linux)

DeepSeek key (optional):

```text
%APPDATA%\TickerLens\TickerLens\deepseek.key
```

---

## Feature parity

| Feature | Plasma | Windows |
|--------|:------:|:-------:|
| Live quotes / ATH / sparklines | ✓ | ✓ |
| Earnings | ✓ | ✓ |
| Portfolio / alerts | ✓ | ✓ |
| News + lexicon sentiment | ✓ | ✓ |
| DeepSeek AI sentiment | ✓ | ✓ |
| Glass UI | ✓ | ✓ (frameless translucent) |
| Panel compact pill | ✓ | Tray compact |
| Multi-monitor drag | ✓ | ✓ |

---

## License

Same as the main project: **GNU GPL v3**. See root `LICENSE`.
