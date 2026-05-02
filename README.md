# claude-clovis

Clovis is a persistent AI agent built on [Claude Code](https://claude.ai/code), reachable via Telegram. It runs as a Docker container and operates on a dedicated git workspace.

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
git clone https://github.com/thiagob/clovis-workspace.git data/workspace
```

For Clovis to push changes, configure git credentials inside the container. Add a GitHub personal access token to `.env`:

```env
GITHUB_TOKEN=your-github-pat
```

Then add to `docker-compose.yml` under `environment`:

```yaml
GITHUB_TOKEN: ${GITHUB_TOKEN}
```

Clovis will use it to authenticate when pushing to the workspace repo.

### 4. Fill in `.env`

```env
BOT_NAME=clovis
TODOIST_API_TOKEN=your-todoist-token
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
1. Ask you to select a login method — choose **Claude account with subscription**
2. Show a URL to complete OAuth in your browser
3. Show a theme/onboarding wizard — complete it fully before exiting

Once inside, install and configure the Telegram plugin:

```
/plugin install telegram@claude-plugins-official
/telegram:configure <your-botfather-token>
```

Exit with Ctrl+C. All state is saved to `./data/` and persists across restarts.

### 6. Run in the background

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
| `TODOIST_API_TOKEN` | No | Todoist integration token |
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
