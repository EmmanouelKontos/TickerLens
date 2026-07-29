#!/usr/bin/env python3
"""
TickerLens News — DeepSeek sentiment helper.

Reads:
  ~/.config/stockglass/ds_payload.json   (request body)
  ~/.config/stockglass/deepseek.key      (API key, mode 600 preferred)

Optional:
  DEEPSEEK_API_KEY env overrides the key file (avoid logging it).

Never prints the API key. stdout = raw API JSON response.
"""
from __future__ import annotations

import json
import os
import sys
import urllib.error
import urllib.request

CFG = os.path.join(os.path.expanduser("~"), ".config", "stockglass")
KEY_PATH = os.path.join(CFG, "deepseek.key")
PAYLOAD_PATH = os.path.join(CFG, "ds_payload.json")
ALLOWED_MODELS = frozenset(
    {
        "deepseek-chat",
        "deepseek-reasoner",
        "deepseek-v4-flash",
        "deepseek-v4-pro",
    }
)
MAX_PAYLOAD_BYTES = 512_000
URL = "https://api.deepseek.com/chat/completions"
TIMEOUT_SEC = 90


def load_key() -> str:
    env = (os.environ.get("DEEPSEEK_API_KEY") or "").strip()
    if env:
        return env
    if os.path.isfile(KEY_PATH):
        with open(KEY_PATH, "r", encoding="utf-8") as f:
            return f.read().strip()
    return ""


def main() -> int:
    if not os.path.isfile(PAYLOAD_PATH):
        print("DS_ERR missing payload", file=sys.stderr)
        return 2

    size = os.path.getsize(PAYLOAD_PATH)
    if size <= 0 or size > MAX_PAYLOAD_BYTES:
        print("DS_ERR bad payload size", file=sys.stderr)
        return 2

    key = load_key()
    if not key or not key.startswith("sk-"):
        print("DS_ERR missing or invalid api key", file=sys.stderr)
        return 2

    try:
        with open(PAYLOAD_PATH, "r", encoding="utf-8") as f:
            payload = json.load(f)
    except Exception as e:
        print(f"DS_ERR payload json: {e}", file=sys.stderr)
        return 2

    if not isinstance(payload, dict):
        print("DS_ERR payload must be object", file=sys.stderr)
        return 2

    model = str(payload.get("model") or "deepseek-chat")
    if model not in ALLOWED_MODELS:
        # allow unknown with warning but default to chat for safety
        payload["model"] = "deepseek-chat"

    # Clamp tokens
    try:
        mt = int(payload.get("max_tokens") or 800)
        payload["max_tokens"] = max(64, min(mt, 4000))
    except Exception:
        payload["max_tokens"] = 800

    body = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(
        URL,
        data=body,
        headers={
            "Content-Type": "application/json",
            "Authorization": "Bearer " + key,
            "User-Agent": "TickerLens-News/1.0",
        },
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=TIMEOUT_SEC) as resp:
            sys.stdout.write(resp.read().decode("utf-8", errors="replace"))
        return 0
    except urllib.error.HTTPError as e:
        err = e.read().decode("utf-8", errors="replace")
        # Never echo Authorization; truncate body
        print(f"DS_ERR HTTP {e.code}: {err[:300]}", file=sys.stderr)
        return 1
    except Exception as e:
        print(f"DS_ERR {e}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
