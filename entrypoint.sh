#!/bin/sh
set -e

# Ensure Claude Code's required files exist in the home/workspace dir
[ -d .claude.json ] && rm -rf .claude.json
[ -f .claude.json ] || echo '{}' > .claude.json

# Pre-accept the trust dialog for this workspace so Claude doesn't prompt on every start
node -e "
  const fs = require('fs'), f = '.claude.json';
  const d = JSON.parse(fs.readFileSync(f, 'utf8'));
  d.projects = d.projects || {};
  d.projects['/home/clovis'] = d.projects['/home/clovis'] || {};
  d.projects['/home/clovis'].hasTrustDialogAccepted = true;
  fs.writeFileSync(f, JSON.stringify(d));
"

if [ ! -f .gitignore ] || ! grep -qF '.claude/' .gitignore; then
  printf '\n# Claude Code internals\n.claude/\n.claude.json\n' >> .gitignore
fi

if [ -n "${GITHUB_TOKEN:-}" ]; then
  git config --global credential.helper \
    '!f() { echo "username=x-token"; echo "password='"$GITHUB_TOKEN"'"; }; f'
  export GH_TOKEN="$GITHUB_TOKEN"
fi

# Install Telegram plugin only on first run — re-installing wipes channel config
_plugins_file=".claude/plugins/installed_plugins.json"
if [ ! -f "$_plugins_file" ] || ! grep -qF '"telegram@claude-plugins-official"' "$_plugins_file"; then
  claude plugins marketplace add anthropics/claude-plugins-official || true
  claude plugins install telegram@claude-plugins-official || true
fi

# gogcli: register OAuth client if a Google OAuth JSON was dropped into the workspace root
for _gog_client in "${HOME}"/client_secret_*.json; do
  [ -f "$_gog_client" ] || break
  gog auth credentials "$_gog_client" || true
  rm -f "$_gog_client"
done

# gogcli: warn if account token is missing (one-time interactive step)
if [ -n "${GOG_GOOGLE_ACCOUNT:-}" ]; then
  if ! gog auth list 2>/dev/null | grep -qF "${GOG_GOOGLE_ACCOUNT}"; then
    echo ""
    echo "gogcli: no token found for ${GOG_GOOGLE_ACCOUNT}."
    echo "Run once to authorize (visit the printed URL, then paste the redirect URL back):"
    echo "  docker compose run --rm agent gog auth add ${GOG_GOOGLE_ACCOUNT} --services gmail,calendar,drive --manual"
    echo ""
  fi
fi

exec claude
