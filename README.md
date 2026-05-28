# notify

![Swift 6.0](https://img.shields.io/badge/Swift-6.0-orange.svg)
![macOS 13+](https://img.shields.io/badge/macOS-13%2B-blue.svg)
![Version 0.2.0](https://img.shields.io/badge/version-0.2.0-brightgreen.svg)
![MIT](https://img.shields.io/badge/license-MIT-green.svg)

`notify` is a macOS command-line tool for sending and managing native notifications with scriptable output, interactive action buttons, and a persistent local event store.

## Why notify

- Script-friendly JSON responses for automation and CI/CD workflows
- Native macOS notifications with categories and action buttons
- Durable local JSONL store for sent notifications and user actions
- LaunchAgent support for background action listening

## Requirements

- macOS 13+
- Swift 6+ (only required for build-from-source)

## Installation

### Recommended (`make install`)

```bash
git clone <repository-url> notify
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

Direct binary execution can fail permission flows because macOS notification APIs expect an app bundle identity. Use `make install` for reliable behavior.

## Quick Start

```bash
# 1) Check current notification permission state
notify status

# 2) Request permission (opens System Settings when needed)
notify request-permission --sound --badge

# 3) Send your first notification
notify send "Hello from notify"

# 4) View stored notifications
notify list
```

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
- `--badge`
- `--provisional`
- `--critical`
- `--json` `--quiet`

Examples:

```bash
notify request-permission
notify request-permission --sound --badge --json
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
- `--sound <default|none>`
- `--interruption-level <passive|active>`
- `--user-info key=value` (repeatable)
- `--json` `--quiet` `--dry-run`

Examples:

```bash
# Minimal
notify send "Build succeeded"

# Full payload for deployment signal
notify send \
  --id deploy-api-prod \
  --title "Deploy in progress" \
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
- `--sound <default|none>`
- `--interruption-level <passive|active>`
- `--user-info key=value` (repeatable)
- `--json` `--quiet` `--dry-run`

Examples:

```bash
notify update deploy-api-prod \
  --title "Deploy complete" \
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

## Action Categories and Buttons

`notify` registers these categories:

- `plain`: no custom buttons
- `alert`: `ACK` (Acknowledge), `OPEN`, `SILENCE`
- `job`: `ACK`, `RETRY`, `OPEN`
- `deploy`: `OPEN`, `ROLLBACK`, `ACK`

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

## Real-World Workflows

### 1) CI/CD deployment lifecycle

```bash
DEPLOY_ID="deploy-api-$(date +%s)"

notify send \
  --id "$DEPLOY_ID" \
  --title "Deploy started" \
  --subtitle "api-service / production" \
  --body "Build #1842 is running" \
  --category deploy \
  --thread "$DEPLOY_ID" \
  --url "https://ci.example.com/builds/1842" \
  --json

# Later in pipeline
notify update "$DEPLOY_ID" \
  --title "Deploy succeeded" \
  --body "All checks green" \
  --url "https://status.example.com/incidents/none" \
  --json
```

### 2) Incident alert with operator actions

```bash
notify send \
  --id incident-payments-502 \
  --title "Payments API incident" \
  --subtitle "HTTP 502 spike" \
  --body "Error rate exceeded 12%" \
  --category alert \
  --thread incident-payments \
  --url "https://runbooks.example.com/payments-incident" \
  --interruption-level active
```

Run listener in another terminal:

```bash
notify listen | jq -c '{ts: .timestamp, action: .action, id: .notification_id}'
```

### 3) Background operations with LaunchAgent

```bash
notify agent install
notify agent status --json | jq '.data'
tail -f "$HOME/Library/Logs/notify/listener.log"
```

### 4) Scripted permission gate

```bash
AUTH=$(notify status --json | jq -r '.data.authorization')
if [ "$AUTH" = "denied" ]; then
  echo "Notifications denied; requesting permission"
  notify request-permission --sound --badge
fi
```

### 5) Thread cleanup after maintenance window

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
