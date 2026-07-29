# TickerLens

**Frosted-glass market widgets for KDE Plasma 6** — free to use, free market data, optional AI news sentiment.

| Widget | What it does |
|--------|----------------|
| **TickerLens** | Watchlist with live prices, day change, sparklines, ATH distance, next earnings, portfolio P/L, alerts |
| **TickerLens News** | Headlines for the same symbols + Good / Neutral / Bad rating (local lexicon or DeepSeek) |

Plugin IDs (for install / upgrades): `com.github.stockglass`, `com.github.stockglass.news`.

---

## Features

### TickerLens
- Live quotes via Yahoo Finance (no API key)
- Configurable refresh, weekend / market hours / US holiday pause
- Optional pause on battery or screen lock
- Distance from all-time high (+ gold **ATH** badge)
- Next earnings date (highlight when soon)
- Intraday sparklines (auto-hide on narrow widgets)
- Day range bar, pre/after-hours when available
- Portfolio shares + avg cost → P/L
- Price / change / near-ATH desktop alerts
- Multi-column layout when wide
- Drag reorder (sort = “As listed”)
- Export / copy watchlist

### TickerLens News
- Follows shared watchlist from TickerLens
- Yahoo Finance headlines (free)
- Free local sentiment lexicon
- Optional **DeepSeek** batch AI ratings (`deepseek-chat` recommended)
- Click headline to open article

---

## Requirements

- KDE Plasma **6**
- Network access to:
  - `query1.finance.yahoo.com`
  - `stockanalysis.com` (earnings)
  - `api.deepseek.com` (optional AI)
- Python 3 (for DeepSeek helper only)

---

## Install

```bash
chmod +x install.sh
./install.sh
```

Desktop: **Add Widgets** → search **TickerLens** and **TickerLens News**.

```bash
plasmawindowed com.github.stockglass
plasmawindowed com.github.stockglass.news
```

After upgrade, if UI is stale:

```bash
kquitapp6 plasmashell; plasmashell --replace &
```

Uninstall:

```bash
kpackagetool6 --type Plasma/Applet --remove com.github.stockglass
kpackagetool6 --type Plasma/Applet --remove com.github.stockglass.news
```

---

## Shared watchlist & secrets

| Path | Purpose |
|------|---------|
| `~/.config/stockglass/watchlist.json` | Symbols shared with News (written by TickerLens) |
| `~/.config/stockglass/deepseek.key` | Optional DeepSeek API key (`chmod 600`) |
| `~/.config/stockglass/rate_news.py` | AI helper (copied by install) |
| `~/.config/stockglass/ds_payload.json` | Temporary AI request body |

Open **TickerLens** at least once so the shared watchlist file is created.

DeepSeek key (optional):

```bash
printf '%s' 'sk-…' > ~/.config/stockglass/deepseek.key
chmod 600 ~/.config/stockglass/deepseek.key
```

Or paste the key in **TickerLens News → Configure**.

---

## Privacy & disclaimer

- Market data providers are unofficial public endpoints; they can rate-limit or change.
- Sentiment is a **heuristic**, not financial advice.
- Do not commit API keys. See [SECURITY.md](SECURITY.md).

---

## Project layout

```
package/                 # TickerLens plasmoid
news-package/            # TickerLens News plasmoid
  contents/code/rate_news.py
install.sh
README.md
LICENSE
SECURITY.md
CHANGELOG.md
```

---

## License

[GPL-3.0-or-later](LICENSE)
