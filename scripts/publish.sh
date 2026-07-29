#!/usr/bin/env bash
set -euo pipefail
export PATH="$HOME/.local/bin:$PATH"
cd "$(dirname "$0")/.."

if ! gh auth status &>/dev/null; then
  echo "Logging into GitHub (browser)…"
  gh auth login -h github.com -p https -w
fi

git remote remove origin 2>/dev/null || true
git remote add origin https://github.com/EmmanouelKontos/TickerLens.git

git push -u origin main

gh repo edit EmmanouelKontos/TickerLens \
  --description "TickerLens — frosted-glass KDE Plasma 6 stock & news widgets. Free market data, ATH, earnings, optional DeepSeek sentiment." \
  --homepage "https://github.com/EmmanouelKontos/TickerLens" \
  --add-topic kde \
  --add-topic plasma \
  --add-topic plasma6 \
  --add-topic qml \
  --add-topic stock-market \
  --add-topic linux \
  --add-topic desktop-widget \
  --add-topic finance || true

echo "Pushed. Repo: https://github.com/EmmanouelKontos/TickerLens"
