#!/usr/bin/env bash
set -eu

# Simple generator: reads .env, extracts DIGITRANSIT_KEY, and writes secrets.lua
ENV_FILE=".env"
OUT_FILE="secrets.lua"

if [[ ! -f "$ENV_FILE" ]]; then
  echo ".env missing — copy from .env.example and fill in values" >&2
  exit 1
fi

# shellcheck disable=SC1090
# Load simple KEY=VALUE pairs from .env (ignore comments)
# This is a minimal parser; avoid complex shells in .env values.

# extract key/value pairs
DIGITRANSIT_KEY=$(grep -E '^\s*DIGITRANSIT_KEY\s*=' "$ENV_FILE" | head -n1 | sed -E 's/^[^=]*=//') || true
WIFI_SSID=$(grep -E '^\s*WIFI_SSID\s*=' "$ENV_FILE" | head -n1 | sed -E 's/^[^=]*=//') || true
WIFI_PWD=$(grep -E '^\s*WIFI_PWD\s*=' "$ENV_FILE" | head -n1 | sed -E 's/^[^=]*=//') || true

if [[ -z "$DIGITRANSIT_KEY" ]]; then
  echo "DIGITRANSIT_KEY not found or empty in .env" >&2
  exit 1
fi

cat > "$OUT_FILE" <<EOF
return {
  DIGITRANSIT_KEY = "${DIGITRANSIT_KEY}",
  WIFI_SSID = ${WIFI_SSID:+"${WIFI_SSID}" or ""},
  WIFI_PWD = ${WIFI_PWD:+"${WIFI_PWD}" or ""}
}
EOF

echo "Generated $OUT_FILE"