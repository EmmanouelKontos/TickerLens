# Security

## Secrets

- **Never commit** DeepSeek (or any) API keys.
- Preferred storage: `~/.config/stockglass/deepseek.key` with mode `600`.
- Widget settings may also hold a key in Plasma’s per-applet config (local only).
- `~/.config/stockglass/ds_payload.json` may contain headlines sent to DeepSeek; it is local and gitignored.

## Network

- Quotes / news: public Yahoo Finance endpoints (unofficial; no key).
- Earnings: public stockanalysis.com API (no key).
- Optional AI: `https://api.deepseek.com/chat/completions` with your key.
- Notifications use `notify-send` when available.

## Hardening notes

- DeepSeek helper (`rate_news.py`) never prints the API key.
- Payload size and model name are clamped/validated in the helper.
- Executable DataSources are limited to watchlist sync, power/lock probes, notifications, and the DeepSeek helper.
- Treat market data and AI sentiment as **informational only**, not investment advice.

## Reporting issues

Open a private security note on the GitHub repository if you find a vulnerability.
