# Security Policy

## Supported versions

Security fixes target the latest `main` branch of this repository.

## Secrets

- **Do not commit** API keys, tokens, or passwords.
- Preferred DeepSeek key path: `~/.config/stockglass/deepseek.key` (`chmod 600`).
- Plasma may also store a key in local applet configuration (machine-local only).
- `ds_payload.json` may contain recent headlines; it is local and gitignored.

## Reporting a vulnerability

Please open a **private** security advisory on GitHub, or contact the repository owner via GitHub, rather than filing a public issue with exploit details.

## Scope notes

- Market data uses unofficial public HTTP APIs; treat them as untrusted input.
- Desktop notifications invoke `notify-send` with shell-escaped arguments.
- Optional AI calls go only to `https://api.deepseek.com`.
- This software is provided under the GPL **without warranty**.
