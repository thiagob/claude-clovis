#!/bin/sh
set -e

if [ -n "${GITHUB_TOKEN:-}" ]; then
  git config --global credential.helper \
    '!f() { echo "username=x-token"; echo "password='"$GITHUB_TOKEN"'"; }; f'
  # gh auth uses GH_TOKEN automatically; alias for clarity
  export GH_TOKEN="$GITHUB_TOKEN"
fi

exec claude --channels plugin:telegram@claude-plugins-official
