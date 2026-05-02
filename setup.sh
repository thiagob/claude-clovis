#!/usr/bin/env bash
set -euo pipefail

# Ask for bot name
read -rp "Bot name (e.g. jarbas): " bot_name
if [ -z "$bot_name" ]; then
  echo "Bot name cannot be empty." >&2
  exit 1
fi

# Create data directories
mkdir -p data/config data/workspace

# Create claude.json as a file (Docker would create it as a directory if missing)
touch data/claude.json

# Set ownership to match the container's claude user (UID 1001)
sudo chown -R 1001:1001 data/

# Bootstrap .env from example if not present
if [ ! -f .env ]; then
  cp .env.example .env
fi

# Write bot name into .env
if grep -q '^BOT_NAME=' .env; then
  sed -i "s/^BOT_NAME=.*/BOT_NAME=${bot_name}/" .env
else
  echo "BOT_NAME=${bot_name}" >> .env
fi

echo "Setup complete. Edit .env with your tokens, then run:"
echo "  docker compose build"
echo "  docker compose run --rm agent"
