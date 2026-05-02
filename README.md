# claude-clovis

Run [Claude Code](https://claude.ai/code) as a persistent Docker container connected to Telegram via the official channels plugin.

## How it works

The container installs Claude Code and starts it with the `--channels` flag, loading the official Telegram plugin (`plugin:telegram@claude-plugins-official`). [Bun](https://bun.sh) is required by the channels MCP server and is installed system-wide. [tini](https://github.com/krallin/tini) is used as PID 1 to reap zombie processes that Bun spawns.

> **Note:** The Telegram channels feature requires a compatible Claude plan (Pro, Max, Team, or Enterprise).

## Prerequisites

- Docker and Docker Compose
- A Claude.ai account (Pro, Max, Team, or Enterprise)
- A Telegram account and bot token from [@BotFather](https://t.me/BotFather)

## Setup

Run the setup script — it creates all required directories and files with the correct permissions:

```bash
./setup.sh
```

Then create a `.env` file with your tokens:

```env
TODOIST_API_TOKEN=your-todoist-token
CLAUDE_CODE_OAUTH_TOKEN="your-claude-oauth-token"
```

> **Note:** Always wrap `CLAUDE_CODE_OAUTH_TOKEN` in double quotes. The token may contain a `#` character, which `.env` parsers treat as a comment delimiter — without quotes, everything after `#` is silently dropped and the token will be invalid.

To get a long-lived OAuth token, run on a machine where you are already logged into Claude Code:

```bash
claude setup-token
```

## First run

Build the image and start interactively to complete the one-time setup wizard:

```bash
docker compose build
docker compose run --rm claude-clovis
```

On first start Claude Code will:
1. Ask you to select a login method — choose **Claude account with subscription**
2. Open a browser OAuth flow (or show a URL to visit manually)
3. Show a theme/onboarding wizard — complete it and do not Ctrl+C mid-wizard

Once the wizard completes, install the Telegram plugin:

```
/plugin install telegram@claude-plugins-official
```

Configure it with your BotFather bot token:

```
/telegram:configure <your-bot-token>
```

Exit with Ctrl+C. All state is saved to `./data/` and persists across restarts.

## Run in the background

```bash
docker compose up -d
```

## Configuration

| Variable | Required | Description |
|---|---|---|
| `CLAUDE_CODE_OAUTH_TOKEN` | Yes | Long-lived auth token from `claude setup-token` |
| `TODOIST_API_TOKEN` | No | Todoist integration token |
| `TZ` | No | Container timezone. Defaults to `America/Sao_Paulo` |

### Volumes

| Host path | Container path | Purpose |
|---|---|---|
| `./data/config` | `/home/claude/.claude` | OAuth tokens, Telegram pairing, sessions, plugins |
| `./data/claude.json` | `/home/claude/.claude.json` | Wizard state, theme preference |
| `./data/workspace` | `/workspace` | Files Claude reads and writes |

> **Important:** `./data/claude.json` must exist as a **file** (not a directory) before the first run. The setup script handles this. If Docker creates it as a directory, remove it and run `setup.sh` again.

## Usage

After setup, open Telegram and message your paired bot. Claude Code will respond as if you were using it in a terminal.

## Logs

```bash
docker compose logs -f
```

## Stopping

```bash
docker compose down
```

State and Telegram pairing are preserved in `./data/`, so the next `docker compose up` resumes without re-authenticating.
