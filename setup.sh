#!/usr/bin/env bash
set -euo pipefail

# Create data directories
mkdir -p data/config data/workspace

# Create claude.json as a file (Docker would create it as a directory if missing)
touch data/claude.json

# Set ownership to match the container's claude user (UID 1001)
sudo chown -R 1001:1001 data/

# Bootstrap .env from example if not present
if [ ! -f .env ]; then
  cp .env.example .env
  echo "Created .env from .env.example — fill in your tokens before continuing."
fi

echo "Setup complete. Edit .env with your tokens, then run:"
echo "  docker compose build"
echo "  docker compose run --rm claude-clovis"
