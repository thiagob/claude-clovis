#!/usr/bin/env bash
set -euo pipefail

echo "This will stop the container and wipe all state in ./data/config and ./data/claude.json."
echo "The workspace (./data/workspace) will NOT be touched."
read -rp "Continue? [y/N] " confirm
if [ "${confirm}" != "y" ] && [ "${confirm}" != "Y" ]; then
  echo "Aborted."
  exit 0
fi

# Stop the container if running
docker compose down --remove-orphans 2>/dev/null || true

# Wipe auth, sessions, plugins, and wizard state
sudo rm -rf data/config data/claude.json

echo "Reset complete. Run ./setup.sh to reinitialize."
