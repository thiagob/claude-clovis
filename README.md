# claude-clovis

Clovis is a persistent AI agent built on [Claude Code](https://claude.ai/code), reachable via Telegram. It runs as a Docker container and operates on a dedicated git workspace.

## Motivation

This project started as an exploration of [openclaw.ai](https://openclaw.ai/) — a cloud-based AI assistant that connects to your email, calendar, todos, and messages. The idea was compelling, but the security implications were not: you are handing a third-party service full access to your Gmail, WhatsApp, and the rest of your personal data, with no real visibility into what it does with it.

The internet has also produced some memorable reminders of what happens when an agent has write access to everything and acts on ambiguous instructions — [like texting your ex](https://www.reddit.com/r/ChatGPT/comments/1sng426/my_openclaw_texted_my_ex/).

Clovis is the alternative: the same concept, but self-hosted, small, and built on Claude Code. You own the container, the credentials never leave your machine, and everything the agent does is visible in git history.

**What it is today:** a Docker wrapper around Claude Code that lets you run a persistent agent reachable via Telegram, using your existing Claude subscription — no API key, no extra cost on top of what you already pay.

**Where it's going:**

- **Easy, reproducible setup** — clone, run `setup.sh`, and have a working agent in minutes ✓
- **MCP tool integrations** — Gmail, Todoist, WhatsApp, Google Calendar, and others will be added incrementally as MCP servers
- **Granular access control** — each MCP tool restricted to read-only by default, so the agent can read your emails without being able to send them, read your calendar without creating events. You decide what it can touch.

> **Compliance note:** Clovis is designed for personal use. If you are considering using it in a work context, your organization may have data governance policies, corporate IT requirements, or regulatory obligations (GDPR, HIPAA, SOC 2, etc.) that govern what tools can access company data. Evaluate accordingly — personal and professional contexts carry very different rules.

## Concept

An agent instance is made of two repos:

```
claude-clovis       ← the shell: container, auth, Telegram, config
clovis-workspace    ← the workspace: git repo Clovis reads and writes
```

**`claude-clovis`** (this repo) is the environment — it defines how the agent runs, how it authenticates, and how it connects to Telegram. You manage this from the host.

**`clovis-workspace`** is where Clovis does its work — a regular git repo mounted into the container at `/workspace`. Clovis can read files, write code, make commits, and push. You review what it did via git history.

This separation keeps infra concerns out of the workspace and gives Clovis a clean, auditable place to operate.

## How it works

The container installs Claude Code and starts it with the `--channels` flag, loading the official Telegram plugin (`plugin:telegram@claude-plugins-official`). [Bun](https://bun.sh) is required by the channels MCP server and is installed system-wide. [tini](https://github.com/krallin/tini) is used as PID 1 to reap zombie processes that Bun spawns.

> **Note:** The Telegram channels feature requires a compatible Claude plan (Pro, Max, Team, or Enterprise).

## Setup

### 1. Clone this repo

```bash
git clone https://github.com/thiagob/claude-clovis.git
cd claude-clovis
```

### 2. Run setup

```bash
./setup.sh
```

The script prompts for the bot name, creates all required directories and files with correct permissions, and generates a `.env` from the example.

### 3. Set up the workspace

Create `clovis-workspace` on GitHub, then clone it into `./data/workspace/`:

```bash
git clone https://github.com/<your-username>/clovis-workspace.git data/workspace
```

For Clovis to push changes, set `GITHUB_TOKEN` in `.env` with a GitHub personal access token — it is already wired into the container and configured for git authentication at startup.

### 4. Fill in `.env`

```env
BOT_NAME=clovis
CLAUDE_CODE_OAUTH_TOKEN="your-claude-oauth-token"
GITHUB_TOKEN=your-github-pat
```

To get a long-lived OAuth token, run on a machine where you are already logged into Claude Code:

```bash
claude setup-token
```

> Always wrap `CLAUDE_CODE_OAUTH_TOKEN` in double quotes — the token may contain a `#` which `.env` parsers treat as a comment delimiter, silently truncating the value.

### 5. Build and run the first-time wizard

```bash
docker compose build
docker compose run --rm agent
```

On first start Claude Code will:
1. Warn that `.claude.json` contains invalid JSON — choose **Reset with default configuration**
2. Ask you to select a login method — choose **Claude account with subscription**
3. Show a URL to complete OAuth in your browser
4. Show a theme/onboarding wizard — complete it fully before exiting

Once inside, install and configure the Telegram plugin:

```
/plugin install telegram@claude-plugins-official
/telegram:configure <your-botfather-token>
```

Exit with Ctrl+C, then start the container in the background:

```bash
docker compose up -d
```

### 6. Pair your Telegram account and lock down access

Open Telegram and send any message to your bot. It will reply with a pairing code.

Attach to the running container and open a Claude Code session:

```bash
docker compose run --rm agent
```

Once inside the Claude Code prompt (not your bash shell), run:

```
/telegram:access pair <code>
/telegram:access policy allowlist
```

The allowlist is critical: without it, anyone who finds your bot's username can send it messages and interact with your agent. Once enabled, only paired accounts are allowed — everyone else is silently dropped.

See the [official channels documentation](https://code.claude.com/docs/en/channels#security) for full details on how the sender allowlist works.

Exit with Ctrl+C. All state is saved to `./data/` and persists across restarts.

### 7. Run in the background

```bash
docker compose up -d
```

Open Telegram and message your bot. Clovis will respond as if you were using Claude Code in a terminal, with full access to the workspace repo.

## Configuration

| Variable | Required | Description |
|---|---|---|
| `BOT_NAME` | Yes | Agent name — sets the Docker container name to `claude-<name>` |
| `CLAUDE_CODE_OAUTH_TOKEN` | Yes | Long-lived auth token from `claude setup-token` |
| `GITHUB_TOKEN` | No | GitHub PAT for Clovis to push to the workspace repo |
| `TZ` | No | Container timezone. Defaults to `America/Sao_Paulo` |

### Volumes

| Host path | Container path | Purpose |
|---|---|---|
| `./data/config` | `/home/claude/.claude` | OAuth tokens, Telegram pairing, sessions, plugins |
| `./data/claude.json` | `/home/claude/.claude.json` | Wizard state, theme preference |
| `./data/workspace` | `/workspace` | The workspace repo Clovis operates on |

> `./data/claude.json` must exist as a **file** before the first run — the setup script handles this. If Docker created it as a directory, remove it and re-run `setup.sh`.

## Commands

```bash
docker compose logs -f     # follow logs
docker compose down        # stop (state preserved in ./data/)
docker compose up -d       # restart
```
