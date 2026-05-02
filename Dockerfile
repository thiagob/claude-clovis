FROM node:22-bookworm-slim

# Bun is required for the channels MCP server
RUN apt-get update && apt-get install -y --no-install-recommends \
        curl ca-certificates git tini unzip \
    && rm -rf /var/lib/apt/lists/*

# Install Bun system-wide
RUN curl -fsSL https://bun.sh/install | BUN_INSTALL=/usr/local bash \
    && ln -sf /usr/local/bin/bun /usr/bin/bun

# Install Claude Code
RUN npm install -g @anthropic-ai/claude-code

# Run as non-root for safety
RUN useradd -m -u 1001 claude
USER claude
WORKDIR /workspace

# tini reaps zombies; Bun spawns subprocesses for the channel MCP
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["claude", "--channels", "plugin:telegram@claude-plugins-official"]