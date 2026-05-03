# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

`open-clovis` runs Claude Code as a persistent Docker container reachable via Telegram. It is a shell — infrastructure only. The actual work happens in a separate `clovis-workspace` repo mounted at `./data/workspace`.

Two-repo model:
- `open-clovis` — container, auth, Telegram config (this repo, managed from the host)
- `clovis-workspace` — git repo Claude operates on (mounted at `/workspace` inside the container)

## Key files

| File | Purpose |
|---|---|
| `Dockerfile` | Builds the image: node:22, Bun, Claude Code, gh CLI |
| `entrypoint.sh` | Configures git credentials from `GITHUB_TOKEN`, then starts `claude --channels` |
| `docker-compose.yml` | Single service `agent`, container named `open-clovis-${BOT_NAME}` |
| `setup.sh` | First-time setup: creates `data/`, sets UID 1001 ownership, bootstraps `.env` |
| `reset.sh` | Wipes `data/config` and `data/claude.json` for a clean re-run of setup |

## Common commands

```bash
./setup.sh                        # first-time init (prompts for bot name)
docker compose build              # rebuild image after Dockerfile changes
docker compose run --rm agent     # interactive first-run wizard
docker compose up -d              # start headless
docker compose logs -f            # follow logs
./reset.sh                        # wipe auth/state, then re-run setup.sh
```

## Volume layout

| Host path | Container path | Notes |
|---|---|---|
| `./data/config` | `/home/claude/.claude` | Auth, sessions, plugins — UID 1001 owned |
| `./data/claude.json` | `/home/claude/.claude.json` | Wizard state — must be a **file**, not a dir |
| `./data/workspace` | `/workspace` | The workspace repo |

`data/` is gitignored. `data/claude.json` must exist as a file before the container starts — Docker creates it as a directory if missing, which breaks Claude Code.

## Container internals

- Runs as user `claude` (UID 1001). Host paths under `data/` must be owned by 1001.
- Claude Code is installed to `/usr/local/lib/node_modules/@anthropic-ai` with UID 1001 ownership so it can self-update.
- `tini` is PID 1 to reap Bun subprocesses spawned by the Telegram MCP server.
- `GITHUB_TOKEN` → git credential helper + `GH_TOKEN` for `gh` CLI (wired in `entrypoint.sh`).

## Git conventions

- No Claude co-authorship in commits (`attribution.commit: ""` in `.claude/settings.json`).
- Always ask before `git push` — it is not auto-allowed.
- `settings.json` is committed (attribution only). Personal permission allows live in `settings.local.json` (gitignored).
