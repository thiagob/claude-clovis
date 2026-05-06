#!/bin/sh
set -e

# Ensure Claude Code's required files exist in the home/workspace dir
[ -d .claude.json ] && rm -rf .claude.json
[ -f .claude.json ] || echo '{}' > .claude.json

if [ ! -f .gitignore ] || ! grep -qF '.claude/' .gitignore; then
  printf '\n# Claude Code internals\n.claude/\n.claude.json\n' >> .gitignore
fi

if [ -n "${GITHUB_TOKEN:-}" ]; then
  git config --global credential.helper \
    '!f() { echo "username=x-token"; echo "password='"$GITHUB_TOKEN"'"; }; f'
  export GH_TOKEN="$GITHUB_TOKEN"
fi

# Register marketplace and install Telegram plugin (both idempotent — no-op if already present)
claude plugins marketplace add anthropics/claude-plugins-official || true
claude plugins install telegram@claude-plugins-official || true

exec claude
