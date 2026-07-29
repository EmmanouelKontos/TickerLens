# Contributing to TickerLens

Thanks for helping improve TickerLens.

## Development

1. Fork and clone the repo.
2. Edit under `package/` (main widget) or `news-package/` (news).
3. Install locally:

```bash
./install.sh
kquitapp6 plasmashell; plasmashell --replace &
```

4. Prefer `plasmawindowed com.github.stockglass` for faster UI iteration.

## Guidelines

- Target **Plasma 6** / Qt 6 QML.
- Do not commit secrets (see `.gitignore` and `SECURITY.md`).
- Keep network code resilient (timeouts, fallbacks, no key logging).
- User-facing strings should remain clear; i18n wrappers (`i18n`) are preferred in config UIs.

## License

By contributing, you agree that your contributions are licensed under the **GNU GPL v3 or later**, the same license as this project.
