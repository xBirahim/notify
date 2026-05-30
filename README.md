# notify

![Swift 6.0](https://img.shields.io/badge/Swift-6.0-orange.svg)
![macOS 13+](https://img.shields.io/badge/macOS-13%2B-blue.svg)
![Version 0.2.0](https://img.shields.io/badge/version-0.2.0-brightgreen.svg)
![MIT](https://img.shields.io/badge/license-MIT-green.svg)

`notify` is a macOS command-line tool for sending and managing native notifications. Designed for **AI agents** running on macOS, it lets agents keep the user informed, ask for decisions via interactive action buttons, and report results — all through native macOS notifications.

## Why notify

- **AI agents can notify you** during long-running tasks without cluttering the terminal
- **Interactive action buttons** let agents ask for confirmation (approve/retry/rollback) — and wait for your response
- **Scriptable JSON output** so agents can parse results and errors programmatically
- **Persistent local store** for auditing past notifications and user actions
- **LaunchAgent support** for background action listening across sessions

## Requirements

- macOS 13+
- Swift 6+ (only required for build-from-source)

## Installation

### Homebrew (recommended)

```bash
brew tap xBirahim/notify
brew install xbirahim/notify/notify
notify request-permission --sound
```

To upgrade: `brew upgrade notify`

### From source (`make install`)

```bash
git clone https://github.com/xBirahim/notify.git
cd notify
make install
```

This installs:

- `~/.local/share/Notify.app` (required app bundle identity for `UNUserNotificationCenter`)
- `~/.local/bin/notify` (launcher)

Add the launcher to your shell path:

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
notify version
```

### Build-only (advanced)

```bash
swift build -c release
cp .build/release/notify /usr/local/bin/
```

Direct binary execution can fail permission flows because macOS notification APIs expect an app bundle identity. Use Homebrew or `make install` for reliable behavior.

## Quick Start

```bash
# 1) Check current notification permission state
notify status

# 2) Request permission (opens System Settings when needed)
notify request-permission --sound

# 3) Send your first notification
notify send "Hello from notify"

# 4) View stored notifications
notify list
```

## AI Agent Skill

The root `SKILL.md` teaches AI agents to:

- Send progress notifications during long tasks
- Ask for confirmation using interactive action buttons
- Report results with status and timing
- Handle permission setup automatically
- Parse JSON output for decision-making

Load `SKILL.md` into your AI agent's context, or configure your tool to include it automatically (OpenCode: add to `skills.paths` or `instructions`; Cursor: add to `.cursorrules`).

## Command Overview

```text
notify
├── status
├── request-permission
├── send
├── update
├── dismiss
├── list
├── get
├── test
├── listen
├── agent
│   ├── install
│   ├── uninstall
│   └── status
└── version
```

## Output Modes

Most commands support these flags:

- `--json`: emit machine-readable JSON
- `--quiet`: suppress non-error output
- `--dry-run`: validate inputs without side effects

`notify version --json` returns a direct JSON object (not the standard command envelope).

### JSON Envelope

Most `--json` command responses use this shape:

```json
{
  "id": "deploy-api-prod",
  "command": "send",
  "status": "delivered",
  "data": {},
  "error": null
}
```

Error responses:

```json
{
  "id": "deploy-api-prod",
  "command": "get",
  "status": "error",
  "data": null,
  "error": {
    "code": "not_found",
    "message": "Notification not found.",
    "detail": null
  }
}
```

## Core Commands

### `notify status`

Show current macOS notification authorization state.

```bash
notify status
notify status --json
```

### `notify request-permission`

Request notification permissions.

Options:

- `--sound`
- `--provisional`
- `--critical`
- `--json` `--quiet`

Examples:

```bash
notify request-permission
notify request-permission --sound --json
notify request-permission --provisional --json
```

If command-line permission prompting fails, `notify` opens System Settings and relaunches itself to complete authorization.

### `notify send`

Send a notification.

Arguments:

- positional `body` (optional if `--body` is provided)

Options:

- `--id <id>`
- `--title <title>`
- `--subtitle <subtitle>`
- `--body <body>`
- `--category <plain|alert|job|deploy>`
- `--thread <thread>`
- `--url <url>`
- `--sound <default\|none\|name>`
- `--interruption-level <passive|active>`
- `--user-info key=value` (repeatable)
- `--json` `--quiet` `--dry-run`

Examples:

```bash
# Minimal
notify send "Build succeeded"

# Full payload
notify send \
  --id deploy-api-prod \
  --title "Operation in progress" \
  --subtitle "api-service / production" \
  --body "Step 2/5: running migrations" \
  --category deploy \
  --thread deploy-api-prod \
  --url "https://grafana.example.com/d/deploy" \
  --sound default \
  --interruption-level active \
  --user-info env=prod \
  --user-info service=api \
  --json

# Validate only
notify send "Will not be sent" --dry-run --json
```

### `notify update`

Replace a notification using an existing ID.

Arguments:

- `id` (required)

Options:

- `--title` `--subtitle` `--body`
- `--category <plain|alert|job|deploy>`
- `--thread <thread>`
- `--url <url>`
- `--sound <default\|none\|name>`
- `--interruption-level <passive|active>`
- `--user-info key=value` (repeatable)
- `--json` `--quiet` `--dry-run`

Examples:

```bash
notify update deploy-api-prod \
  --title "Operation complete" \
  --body "Completed in 3m42s" \
  --sound default

notify update deploy-api-prod --body "Rollback started" --category deploy --json
```

### `notify dismiss`

Dismiss notifications by ID, by thread, or all.

Target options (mutually exclusive):

- positional `id` or `--id <id>`
- `--thread <thread>`
- `--all`

Scope options:

- `--pending`
- `--delivered`

If no scope is provided, both pending and delivered notifications are dismissed.

Examples:

```bash
notify dismiss deploy-api-prod
notify dismiss --thread deploy-api-prod
notify dismiss --all
notify dismiss --all --pending
notify dismiss --thread incident-payments --delivered --json
```

### `notify list`

List notifications from the local store.

Options:

- `--thread <thread>`
- `--json` `--quiet`

Examples:

```bash
notify list
notify list --thread deploy-api-prod
notify list --json
```

### `notify get`

Retrieve one notification by ID from the local store.

```bash
notify get deploy-api-prod
notify get deploy-api-prod --json
```

### `notify test`

Send a standard test notification (`id=notify-test`).

```bash
notify test
notify test --interruption-level active --json
notify test --dry-run
```

### `notify listen`

Run a foreground listener for notification action events. This process stays alive until `SIGINT`/`SIGTERM`.

```bash
notify listen
```

Each action event is emitted to stdout as JSON (JSON Lines), for example:

```json
{"action":"OPEN","category":"deploy","notification_id":"deploy-api-prod","timestamp":"2026-05-28T19:12:22Z","url":"https://grafana.example.com/d/deploy"}
```

### `notify agent`

Manage the background LaunchAgent that runs `notify listen`.

```bash
notify agent install
notify agent status
notify agent uninstall
```

Paths used by the agent:

- plist: `~/Library/LaunchAgents/io.notify.listener.plist`
- log: `~/Library/Logs/notify/listener.log`

`notify agent status` reports service state as one of `running`, `loaded`, or `not loaded`.

### `notify version`

Print installed version information.

```bash
notify version
notify version --json
```

## Sounds

`notify` supports macOS system sounds and custom sound files. Pass the sound name (without extension) via `--sound`:

```bash
notify send "Hello" --sound Purr
notify send "Silent" --sound none
```

### Built-in system sounds

| Name | Description |
|---|---|
| `Basso` | Deep bass |
| `Blow` | Air blow |
| `Bottle` | Glass bottle |
| `Frog` | Frog croak |
| `Funk` | Funky riff |
| `Glass` | Glass breaking |
| `Hero` | Heroic fanfare |
| `Morse` | Morse code |
| `Ping` | Sonar ping |
| `Pop` | Pop cork |
| `Purr` | Cat purr |
| `Sosumi` | Classic macOS chime |
| `Submarine` | Submarine sonar |
| `Tink` | Small bell |
| `default` | System default notification sound |
| `none` | No sound |

Sound files are loaded from `/System/Library/Sounds/` and `~/Library/Sounds/`. Supported formats: `.aiff`, `.caf`, `.wav`, `.mp3`, `.m4a`.

```bash
# Custom sound from ~/Library/Sounds/
notify send "Custom alert" --sound MyAlert.caf

# Combine with interruption level for urgent alerts
notify send "Critical failure" --sound Sosumi --interruption-level active
```

## Action Categories and Buttons

`notify` registers these categories:

| Category | Buttons | Use case |
|---|---|---|
| `plain` | *(none)* | Pure information, no interaction |
| `alert` | ACK, OPEN, SILENCE | Alert that needs acknowledgment |
| `job` | ACK, RETRY, OPEN | Background job the user can retry |
| `deploy` | OPEN, ROLLBACK, ACK | Operation to approve or rollback |

When user clicks the notification body (default action) or the `OPEN` button, `notify` opens the attached `--url` if provided.

## Local Store and Querying

`notify` persists records as JSON Lines:

- `~/Library/Application Support/notify/notifications.jsonl`
- `~/Library/Application Support/notify/actions.jsonl`

`notify list` returns the latest stored record per notification ID (deduplicated from append-only history).

Practical queries:

```bash
# Latest 20 action events
tail -n 20 "$HOME/Library/Application Support/notify/actions.jsonl"

# Find all deploy actions
jq -c 'select(.category == "deploy")' "$HOME/Library/Application Support/notify/actions.jsonl"

# List all notifications for a thread
notify list --thread deploy-api-prod --json | jq '.data[] | {id, title, body, updated_at}'

# Count retry actions
jq -r 'select(.action == "RETRY") | .notification_id' \
   "$HOME/Library/Application Support/notify/actions.jsonl" | wc -l
```

## AI Agent Workflows

### 1) Notify the user during a long task

Send progressive updates so the user knows what your agent is doing.

```bash
TASK_ID="build-site-$(date +%s)"

notify send \
  --id "$TASK_ID" \
  --title "Building site" \
  --body "Step 1/4: fetching content..." \
  --category plain \
  --thread "$TASK_ID" \
  --json

# ... do work ...
notify update "$TASK_ID" --body "Step 2/4: generating pages..." --json

# ... do work ...
notify update "$TASK_ID" --body "Step 3/4: optimizing assets..." --json

# Final update
notify update "$TASK_ID" \
  --title "Build complete" \
  --body "Generated 342 pages in 1.2s" \
  --sound default \
  --json
```

### 2) Ask the user for confirmation

Use action categories — `deploy`, `job`, or `alert` — to attach interactive buttons, then run `notify listen` to capture the user's choice.

```bash
# Ask user to confirm
notify send \
  --id cleanup-db \
  --title "Cleanup old records?" \
  --body "Delete 1,204 stale records from the database? This cannot be undone." \
  --category job \
  --thread cleanup \
  --json

# Wait up to 2 minutes for response
RESPONSE=$(timeout 120 notify listen 2>/dev/null | head -n 1 | jq -r '.action // "timeout"')

if [ "$RESPONSE" = "ACK" ] || [ "$RESPONSE" = "OPEN" ]; then
  # User approved — proceed
  notify update cleanup-db --title "Cleaning up..." --body "Removing 1,204 records..." --json
  # ... perform operation ...
  notify update cleanup-db --title "Cleanup complete" --body "Removed 1,204 records in 3.2s" --sound default --json
elif [ "$RESPONSE" = "RETRY" ]; then
  notify update cleanup-db --body "User requested retry — re-evaluating" --json
elif [ "$RESPONSE" = "timeout" ]; then
  notify update cleanup-db --title "Operation skipped" --body "No response received — cancelled" --json
fi
```

### 3) Report task result

After completing a task, replace the progress notification with a clear result.

```bash
TASK_ID="backup-db-$(date +%s)"

notify send \
  --id "$TASK_ID" \
  --title "Starting backup" \
  --body "Backing up production database..." \
  --category plain \
  --thread "$TASK_ID" \
  --json

# ... perform backup ...
BACKUP_SIZE="2.4 GB"
DURATION="47s"

notify update "$TASK_ID" \
  --title "Backup complete" \
  --body "Database backed up successfully (${BACKUP_SIZE}, ${DURATION})" \
  --sound default \
  --json
```

On failure:

```bash
notify update "$TASK_ID" \
  --title "Backup failed" \
  --body "Database backup failed after ${DURATION}" \
  --interruption-level active \
  --json
```

### 4) Scripted permission gate for agents

```bash
AUTH=$(notify status --json | jq -r '.data.authorization')
if [ "$AUTH" = "denied" ] || [ "$AUTH" = "notDetermined" ]; then
  echo "Requesting notification permission"
  notify request-permission --sound
fi
```

### 5) Clean up notification threads

```bash
notify dismiss --thread maintenance-db-cluster --delivered --json
notify list --thread maintenance-db-cluster --json
```

## Exit Codes

- `0`: success
- `44`: not found
- `64`: usage
- `65`: invalid input
- `69`: permission denied
- `70`: system error
- `124`: timeout
- `130`: interrupted

## Development

```bash
swift build
swift test
swift build -c release
make install
```

## Notes and Constraints

- `notify` can only manage notifications owned by its own app identity.
- `send` and `update` both use `UNNotificationRequest`; same `--id` replaces existing notification content.
- Notifications and interaction callbacks require an active macOS user session.
- For reliable action capture across sessions, use `notify agent install`.
- When used by AI agents, prefer `--json` output for reliable error checking.
- `notify listen` times out automatically; for scripted agent workflows, wrap it with `timeout` to avoid indefinite hangs.
