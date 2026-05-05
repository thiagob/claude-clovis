#!/usr/bin/env bash
set -euo pipefail

echo "This will stop the container and wipe Claude state (.claude/ and .claude.json) inside ./data/workspace."
echo "Workspace files (your code, commits) will NOT be touched."
read -rp "Continue? [y/N] " confirm
if [ "${confirm}" != "y" ] && [ "${confirm}" != "Y" ]; then
  echo "Aborted."
  exit 0
fi

# Stop the container if running
docker compose down --remove-orphans 2>/dev/null || true

# Wipe auth, sessions, plugins, and wizard state
sudo rm -rf data/workspace/.claude data/workspace/.claude.json

echo "Reset complete. Run docker compose run --rm agent to reinitialize."
