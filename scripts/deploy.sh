#!/usr/bin/env bash
set -eu

# Deploy wrapper: generate secrets.lua and upload secrets + compiled lua files
# Usage: ./scripts/deploy.sh [PORT]
# If PORT is passed, it will be forwarded to make targets (e.g. /dev/ttyUSB0)

PORT_ARG=${1:-}
MAKE_ARGS=()
if [[ -n "$PORT_ARG" ]]; then
  MAKE_ARGS+=("PORT=$PORT_ARG")
fi

echo "Generating secrets.lua from .env"
./scripts/generate_secrets.sh

echo "Uploading secrets.lua"
nodemcu-uploader --port ${PORT_ARG:-$(make -s -p | awk -F ':=' '/^PORT /{gsub(" ","",$$2); print $$2; exit}') } --baud 115200 upload secrets.lua || nodemcu-uploader upload secrets.lua

# Upload compiled lua & restart
make "${MAKE_ARGS[@]}" upload-c restart

# cleanup
rm -f secrets.lua

echo "Deploy complete."