#!/bin/sh
set -e

# Pre-accept the workspace trust dialog so Claude doesn't hang waiting for input
CLAUDE_JSON="${HOME}/.claude.json"
[ -d "$CLAUDE_JSON" ] && rm -rf "$CLAUDE_JSON"
[ -f "$CLAUDE_JSON" ] || echo '{}' > "$CLAUDE_JSON"
node -e "
  const fs = require('fs'), f = process.env.HOME + '/.claude.json';
  const d = JSON.parse(fs.readFileSync(f, 'utf8'));
  d.projects = d.projects || {};
  d.projects['/home/clovis/workspace'] = d.projects['/home/clovis/workspace'] || {};
  d.projects['/home/clovis/workspace'].hasTrustDialogAccepted = true;
  fs.writeFileSync(f, JSON.stringify(d));
"

if [ -n "${GITHUB_TOKEN:-}" ]; then
  git config --global credential.helper \
    '!f() { echo "username=x-token"; echo "password='"$GITHUB_TOKEN"'"; }; f'
  export GH_TOKEN="$GITHUB_TOKEN"
fi

# Register any N8N_MCP_* env vars as MCP servers in Claude's settings.
# Each var becomes a named MCP entry: N8N_MCP_GOOGLE → "n8n-google"
# URLs are set directly in docker-compose.yml (no secrets, internal network only).
# _SETTINGS="${HOME}/.claude/settings.json"
# if [ -f "$_SETTINGS" ] && command -v jq > /dev/null 2>&1; then
#   env | grep '^N8N_MCP_' | grep -v '^N8N_MCP_TOKEN=' | while IFS='=' read -r _key _url; do
#     [ -z "$_url" ] && continue
#     _name="n8n-$(echo "$_key" | sed 's/^N8N_MCP_//' | tr '[:upper:]' '[:lower:]')"
#     _tmp=$(mktemp)
#     if [ -n "${N8N_MCP_TOKEN:-}" ]; then
#       jq --arg n "$_name" --arg u "$_url" --arg t "$N8N_MCP_TOKEN" \
#         '.mcpServers[$n] = {"type": "http", "url": $u, "headers": {"Authorization": ("Bearer " + $t)}}' \
#         "$_SETTINGS" > "$_tmp" && mv "$_tmp" "$_SETTINGS"
#     else
#       jq --arg n "$_name" --arg u "$_url" \
#         '.mcpServers[$n] = {"type": "http", "url": $u}' "$_SETTINGS" > "$_tmp" && mv "$_tmp" "$_SETTINGS"
#     fi
#     echo "entrypoint: registered MCP server '$_name' → $_url"
#   done
# fi

# Telegram plugin — install once, skip forever after
# Sentinel lives inside the channels dir so wiping channels/ triggers a clean reinstall.
_TELEGRAM_SENTINEL="${HOME}/.claude/channels/telegram/.installed"
_TELEGRAM_PLUGIN_DIR="${HOME}/.claude/plugins/marketplaces/claude-plugins-official/external_plugins/telegram"

if [ -n "${TELEGRAM_BOT_TOKEN:-}" ]; then
  if [ ! -f "$_TELEGRAM_SENTINEL" ] || [ ! -d "$_TELEGRAM_PLUGIN_DIR" ]; then
    echo "entrypoint: first run — installing Telegram plugin"
    claude plugins install telegram@claude-plugins-official || true
    mkdir -p "${HOME}/.claude/channels/telegram"
    touch "$_TELEGRAM_SENTINEL"
    echo "entrypoint: Telegram plugin installed"
  else
    echo "entrypoint: Telegram plugin already installed, skipping"
  fi
  exec claude --channels plugin:telegram@claude-plugins-official
else
  exec claude
fi
