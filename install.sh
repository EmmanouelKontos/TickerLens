#!/usr/bin/env bash
# Install TickerLens + TickerLens News (Plasma 6 plasmoids)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"

install_one() {
  local PKG="$1"
  local ID="$2"
  local LABEL="$3"

  if [[ ! -f "$PKG/metadata.json" ]]; then
    echo "error: $PKG/metadata.json not found" >&2
    return 1
  fi

  if kpackagetool6 --type Plasma/Applet --list 2>/dev/null | grep -Fq "$ID"; then
    echo "Updating $LABEL ($ID) …"
    kpackagetool6 --type Plasma/Applet --upgrade "$PKG"
  else
    echo "Installing $LABEL ($ID) …"
    kpackagetool6 --type Plasma/Applet --install "$PKG"
  fi
}

if ! command -v kpackagetool6 >/dev/null 2>&1; then
  echo "error: kpackagetool6 not found (install plasma-framework / plasma-workspace)" >&2
  exit 1
fi

install_one "$ROOT/package" "com.github.stockglass" "TickerLens"
install_one "$ROOT/news-package" "com.github.stockglass.news" "TickerLens News"

mkdir -p "$HOME/.config/stockglass"
chmod 700 "$HOME/.config/stockglass" 2>/dev/null || true

if [[ -f "$ROOT/news-package/contents/code/rate_news.py" ]]; then
  cp -f "$ROOT/news-package/contents/code/rate_news.py" "$HOME/.config/stockglass/rate_news.py"
  chmod 755 "$HOME/.config/stockglass/rate_news.py"
fi

# Harden key file if present
if [[ -f "$HOME/.config/stockglass/deepseek.key" ]]; then
  chmod 600 "$HOME/.config/stockglass/deepseek.key"
fi

echo
echo "Done."
echo "  Add widgets: right-click desktop → Add Widgets"
echo "    • TickerLens      — prices, ATH, earnings, charts, portfolio, alerts"
echo "    • TickerLens News — headlines + sentiment for the same watchlist"
echo
echo "Shared watchlist: ~/.config/stockglass/watchlist.json"
echo "Open TickerLens once so News can sync symbols."
echo
echo "Reload Plasma if UI looks stale:"
echo "  kquitapp6 plasmashell; plasmashell --replace &"
echo
echo "Preview:"
echo "  plasmawindowed com.github.stockglass"
echo "  plasmawindowed com.github.stockglass.news"
echo
echo "Uninstall:"
echo "  kpackagetool6 --type Plasma/Applet --remove com.github.stockglass"
echo "  kpackagetool6 --type Plasma/Applet --remove com.github.stockglass.news"
