# TickerLens

**Frosted-glass market widgets for KDE Plasma 6.**

Free to use. Free market data. Optional AI news sentiment.

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)
[![Plasma](https://img.shields.io/badge/Plasma-6-blueviolet)](https://kde.org/plasma-desktop/)
[![Platform](https://img.shields.io/badge/platform-Linux-lightgrey)](#requirements)

| Widget | Role |
|--------|------|
| **TickerLens** | Live watchlist — prices, ATH, earnings, sparklines, portfolio, alerts |
| **TickerLens News** | Headlines for the same symbols + Good / Neutral / Bad sentiment |

Plugin IDs: `com.github.stockglass` · `com.github.stockglass.news`

Repository: [github.com/EmmanouelKontos/TickerLens](https://github.com/EmmanouelKontos/TickerLens)

---

## Highlights

- Modern **glass** UI that fits Plasma
- **No API key** required for quotes, ATH, earnings, or news
- Optional **DeepSeek** ratings for headlines (your key, offline lexicon fallback)
- Shared watchlist between price widget and news widget
- Privacy-minded: secrets stay in `~/.config/stockglass/`, never in the repo

---

## Features

### TickerLens
- Live quotes (Yahoo Finance public endpoints)
- Day change $ / %, sparklines (hide when the widget is narrow)
- Distance from **all-time high** + ATH badge
- **Next earnings** date (soon highlighted)
- Pre / after-hours when available
- Portfolio: shares + average cost → P/L
- Desktop **alerts** (price, day change, near ATH)
- Multi-column when wide; drag reorder when sort is “As listed”
- Weekend / market hours / US holiday pause; optional battery & lock pause
- Export / copy watchlist

### TickerLens News
- Follows the TickerLens shared watchlist
- Yahoo Finance headlines (free)
- Free local **lexicon** sentiment
- Optional **DeepSeek** batch AI sentiment (`deepseek-chat` recommended)
- Click a headline to open the article

---

## Requirements

- KDE **Plasma 6**
- Network access to:
  - `query1.finance.yahoo.com` — quotes & news  
  - `stockanalysis.com` — earnings  
  - `api.deepseek.com` — optional AI only  
- **Python 3** — only for the optional DeepSeek helper

---

## Install

### Download (recommended)

Get installers from **[Releases](https://github.com/EmmanouelKontos/TickerLens/releases)**:

| Platform | Asset | How |
|----------|--------|-----|
| **Windows 11** | `TickerLens-windows-x64-*-setup.exe` | Run the installer (recommended) |
| **Windows 11** | `TickerLens-windows-x64-*.zip` | Portable: extract → run **`TickerLens.exe`** |
| **Linux Plasma 6** | `TickerLens-linux-plasma6-*.tar.gz` | Extract → `./install.sh` |

### From source (Linux Plasma)

```bash
git clone https://github.com/EmmanouelKontos/TickerLens.git
cd TickerLens
chmod +x install.sh
./install.sh
```

Then: desktop → **Add Widgets** → search **TickerLens** and **TickerLens News**.

Preview:

```bash
plasmawindowed com.github.stockglass
plasmawindowed com.github.stockglass.news
```

After an upgrade, if the UI looks stale:

```bash
kquitapp6 plasmashell; plasmashell --replace &
```

Uninstall:

```bash
kpackagetool6 --type Plasma/Applet --remove com.github.stockglass
kpackagetool6 --type Plasma/Applet --remove com.github.stockglass.news
```

---

## Updates

When **Check for updates** is enabled, the Plasma widgets query
[GitHub Releases](https://github.com/EmmanouelKontos/TickerLens/releases) about once a day.
If a newer version is found, you get a desktop notification and a popup with:

- **Install now** — downloads the matching asset and upgrades the Plasma widgets via `install.sh`
- **Open page** — release notes and manual download
- **Later** — remind again after the next daily check
- **Skip this version** — do not prompt again until a newer release

Install always requires your confirmation. Disable checks anytime in Configure / Settings.

## Configuration tips

1. Open **TickerLens** once so it writes  
   `~/.config/stockglass/watchlist.json`  
   (News reads this by default.)
2. Optional DeepSeek key:

```bash
printf '%s' 'sk-…' > ~/.config/stockglass/deepseek.key
chmod 600 ~/.config/stockglass/deepseek.key
```

Or paste the key under **TickerLens News → Configure**.  
Recommended model: **`deepseek-chat`**.

---

## Local files (not in git)

| Path | Purpose |
|------|---------|
| `~/.config/stockglass/watchlist.json` | Shared symbols |
| `~/.config/stockglass/deepseek.key` | API key (mode 600) |
| `~/.config/stockglass/rate_news.py` | AI helper (installed by `install.sh`) |
| `~/.config/stockglass/ds_payload.json` | Temporary AI request body |
| `~/.config/stockglass/update_state.json` | Last update-check / dismissed version (Plasma) |

---

## Windows 11

A separate native Windows port lives in [`windows-native/`](windows-native/).
It uses WPF/.NET 8, DirectWrite/DirectX rendering, and the Windows 11 DWM
Desktop Acrylic system backdrop.

```powershell
dotnet publish windows-native\TickerLens.Native.csproj -c Release -r win-x64 --self-contained true
```

See [windows/README.md](windows/README.md) for build requirements and feature parity with Plasma.

---

## Project layout

```
package/           # Plasma 6 — TickerLens
news-package/      # Plasma 6 — TickerLens News
windows-native/    # Windows 11 native WPF / DWM Acrylic app
windows/           # Legacy Qt app and installer resources
install.sh         # Linux Plasma install
README.md
LICENSE            # GNU GPL v3
SECURITY.md
CHANGELOG.md
```

---

## License

This project is licensed under the **GNU General Public License v3.0 or later**.  
See [LICENSE](LICENSE) for the full text.

You may use, share, and modify TickerLens freely under the GPL.  
There is **no warranty**; market data and sentiment are **not financial advice**.

### Third-party data

- Yahoo Finance and stockanalysis.com are used via public endpoints without affiliation.  
- Those services may change or rate-limit access.  
- DeepSeek is optional and subject to [DeepSeek’s terms](https://www.deepseek.com/).

---

## Security

See [SECURITY.md](SECURITY.md). **Never commit API keys.**

---

## Contributing

Issues and pull requests are welcome. Please keep secrets out of commits and test with Plasma 6.

---

## Author

[Emmanouel Kontos](https://github.com/EmmanouelKontos)
