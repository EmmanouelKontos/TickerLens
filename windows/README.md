# TickerLens for Windows 11

The current Windows application lives in `windows-native/` and is an independent
**WPF/.NET 8 Windows 11 app**. It does not share a UI stack with the KDE widgets.

- Frosted glass floating **Markets** + **News** panels  
- Looks close to the Plasma widgets (dark glass, badges, sparklines, sentiment)  
- System tray control  
- Free market data and headlines from Yahoo Finance

This is **not** a Plasma or Qt build. Its UI and lifecycle are Windows-native.

---

## Why this approach?

| Approach | Verdict |
|----------|---------|
| Plasma QML on Windows | Not practical |
| Share one QML plasmoid | Too many KDE-only APIs |
| **Native WPF + DWM app** | Real Windows composition, typography, controls, and HWND behavior |
| Electron | Heavier, less “native widget” feel |

---

## Look & feel (Windows)

- Frameless translucent windows with soft shadow  
- Native **Windows 11 Desktop Acrylic / rounded corners** via DWM
- Drag title bar · resize grip · always-on-top option  
- Tray icon: show/hide Markets or News, Quit  

---

## Build the native Windows app

Install the .NET 8 SDK, then:

```powershell
dotnet publish windows-native\TickerLens.Native.csproj -c Release -r win-x64 --self-contained true
```

Output: `windows-native\bin\Release\...\publish\TickerLens.exe`.

### Run

Double-click **TickerLens.exe** or:

```powershell
.\windows-native\bin\Release\net8.0-windows10.0.19041.0\win-x64\publish\TickerLens.exe
```

Config lives in:

```text
%APPDATA%\TickerLens\native-settings.json
```

---

The Windows publish can also be cross-compiled with the .NET 8 SDK on Linux by
setting `EnableWindowsTargeting`, which is already enabled in the project.

---

## Feature map

| Feature | Windows app |
|---------|:-----------:|
| Live quotes, day change | ✓ |
| Sparklines (hide when narrow) | ✓ |
| ATH distance | ✓ |
| News + local headline sentiment | ✓ |
| Native Desktop Acrylic | ✓ |
| Tray | ✓ (replaces panel pill) |

---

## License

GNU GPL v3 — same as the main TickerLens repository.
