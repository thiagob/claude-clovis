FROM node:22-bookworm-slim

# Bun is required for the Telegram plugin MCP server
RUN apt-get update && apt-get install -y --no-install-recommends \
        curl ca-certificates git tini unzip \
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update && apt-get install -y --no-install-recommends gh \
    && rm -rf /var/lib/apt/lists/*

# Install Bun system-wide
RUN curl -fsSL https://bun.sh/install | BUN_INSTALL=/usr/local bash \
    && ln -sf /usr/local/bin/bun /usr/bin/bun

# Install Claude Code and give the clovis user ownership so it can self-update
RUN npm install -g @anthropic-ai/claude-code \
    && chown -R 1001:1001 /usr/local/lib/node_modules/@anthropic-ai \
    && chown 1001:1001 /usr/local/bin/claude

# Run as non-root for safety
RUN useradd -m -u 1001 clovis

COPY --chown=clovis:clovis entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER clovis
WORKDIR /home/clovis

# tini reaps zombies; Bun spawns subprocesses for the Telegram plugin MCP server
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/entrypoint.sh"]