#!/usr/bin/env bash
set -euo pipefail

# Ask for bot name
read -rp "Bot name (e.g. jarbas): " bot_name
if [ -z "$bot_name" ]; then
  echo "Bot name cannot be empty." >&2
  exit 1
fi

# Create data directory (sudo needed if data/ is root-owned from a previous run)
sudo mkdir -p data/workspace

# Set ownership to match the container's clovis user (UID 1001)
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

# Prompt for Telegram bot token
read -rp "Telegram bot token (from @BotFather, leave blank to set later): " telegram_token
if [ -n "$telegram_token" ]; then
  if grep -q '^TELEGRAM_BOT_TOKEN=' .env; then
    sed -i "s/^TELEGRAM_BOT_TOKEN=.*/TELEGRAM_BOT_TOKEN=${telegram_token}/" .env
  else
    echo "TELEGRAM_BOT_TOKEN=${telegram_token}" >> .env
  fi
fi

echo "Setup complete. Edit .env with your tokens, then run:"
echo "  docker compose build"
echo "  docker compose run --rm agent"
