# notify

![Swift 6.0](https://img.shields.io/badge/Swift-6.0-orange.svg)
![macOS 13+](https://img.shields.io/badge/macOS-13%2B-blue.svg)
![Version 0.2.0](https://img.shields.io/badge/version-0.2.0-brightgreen.svg)
![MIT](https://img.shields.io/badge/license-MIT-green.svg)

---

`notify` is a macOS CLI to send and manage native macOS notifications with stable, scriptable output, action categories, and a local event store.

- **Scriptable** — JSON output for easy integration with shell scripts, CI pipelines, and monitoring tools
- **Actionable** — Rich notification categories with custom buttons
- **Trackable** — Local persistent store of sent notifications and actions
- **Automateable** — Background listener via LaunchAgent

---

## Requirements

- macOS 13+
- Swift 6+ (to build from source)

---

## Installation

### From source

```bash
git clone https://github.com/your-org/notify.git
cd notify
make install
export PATH="$HOME/.local/bin:$PATH"
notify version
```

This creates:

- `~/.local/share/Notify.app` — bundled executable with app identity (required by `UNUserNotificationCenter`)
- `~/.local/bin/notify` — launcher script

Make sure `~/.local/bin` is in your `PATH`:

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
```

### Build only

```bash
swift build -c release
cp .build/release/notify /usr/local/bin/
```

> **Note:** Running the binary directly without the app bundle may cause permission prompts to fail, as `UNUserNotificationCenter` requires a bundle identity. Use `make install` whenever possible.

---

## Commands

### `notify status`

Show macOS notification permission state.

| Option | Flag | Description |
|--------|------|-------------|
| `--json` | | Machine-readable JSON output |
| `--quiet` | | Suppress non-error output |

### `notify request-permission`

Request macOS notification authorization.

| Option | Flag | Description |
|--------|------|-------------|
| `--sound` | ✓ | Request sound permission |
| `--badge` | ✓ | Request badge permission |
| `--provisional` | ✓ | Request provisional permission |
| `--critical` | ✓ | Request critical alert permission |
| `--json` | | Machine-readable JSON output |
| `--quiet` | | Suppress non-error output |

### `notify send`

Send a notification.

| Argument | Required | Description |
|----------|----------|-------------|
| `body` | | Notification body text (positional) |

| Option | Description |
|--------|-------------|
| `--id` | Stable notification identifier |
| `--title` | Notification title |
| `--subtitle` | Notification subtitle |
| `--body` | Notification body (overrides positional body) |
| `--category` | Category: `plain`, `alert`, `job`, `deploy` |
| `--thread` | Thread identifier for macOS grouping |
| `--url` | URL to attach |
| `--user-info` | Add metadata entry as `key=value` (repeatable) |
| `--sound` | Sound type: `default`, `none` (default: `default`) |
| `--interruption-level` | Interruption level: `passive`, `active` |

### `notify update`

Update a notification by replacing it (same engine as `send`).

| Argument | Required | Description |
|----------|----------|-------------|
| `id` | ✓ | Notification identifier |

| Option | Description |
|--------|-------------|
| `--title` | Notification title |
| `--subtitle` | Notification subtitle |
| `--body` | Notification body |
| `--category` | Category: `plain`, `alert`, `job`, `deploy` |
| `--thread` | Thread identifier |
| `--url` | URL to attach |
| `--user-info` | Add metadata entry as `key=value` (repeatable) |
| `--interruption-level` | Interruption level: `passive`, `active` |
| `--json` | Machine-readable JSON output |
| `--quiet` | Suppress non-error output |
| `--dry-run` | Validate input without sending |

### `notify dismiss`

Dismiss pending and/or delivered notifications.

| Argument | Required | Description |
|----------|----------|-------------|
| `id` | | Notification identifier (positional) |

| Option | Description |
|--------|-------------|
| `--id` | Notification identifier |
| `--thread` | Dismiss all notifications in this thread group |
| `--all` | Dismiss all notifications owned by notify |
| `--pending` | Dismiss pending (undelivered) notifications |
| `--delivered` | Dismiss delivered notifications |
| `--json` | Machine-readable JSON output |
| `--quiet` | Suppress non-error output |
| `--dry-run` | Validate input without dismissing |

> `--id`, `--thread`, and `--all` are mutually exclusive.
> By default (without `--pending` or `--delivered`), both pending and delivered notifications are dismissed.

### `notify list`

List notifications from the local store.

| Option | Description |
|--------|-------------|
| `--thread` | Filter by thread identifier |
| `--json` | Machine-readable JSON output |
| `--quiet` | Suppress non-error output |

### `notify get`

Get one notification by identifier from the local store.

| Argument | Required | Description |
|----------|----------|-------------|
| `id` | ✓ | Notification identifier |

| Option | Description |
|--------|-------------|
| `--json` | Machine-readable JSON output |
| `--quiet` | Suppress non-error output |

### `notify test`

Send a test notification.

| Option | Description |
|--------|-------------|
| `--interruption-level` | Interruption level: `passive`, `active` |
| `--json` | Machine-readable JSON output |
| `--quiet` | Suppress non-error output |
| `--dry-run` | Validate input without sending |

### `notify listen`

Listen for notification action callbacks (long-running process).

This command runs until interrupted (`Ctrl+C`, `SIGTERM`, or `SIGINT`) and outputs structured JSON events to stdout when the user interacts with notification action buttons. Use `notify agent install` to run it as a background LaunchAgent.

### `notify agent`

Manage the background listener LaunchAgent.

#### `notify agent install`

Install and load the LaunchAgent for background notification listening.

Creates `~/Library/LaunchAgents/io.notify.listener.plist` and loads it with `launchctl`.
Logs are written to `~/Library/Logs/notify/listener.log`.

#### `notify agent uninstall`

Unload and remove the LaunchAgent.

#### `notify agent status`

Check if the listener LaunchAgent is installed and running.

Output:
```
Plist: installed
Service: running
```

Also supports `--json` for machine-readable status.

### `notify version`

Print the notify version.

| Option | Description |
|--------|-------------|
| `--json` | Machine-readable JSON output with version, Swift version, and platform |
| `--quiet` | Suppress output |

---

## Global options

These options are available on most commands:

| Option | Flag | Description |
|--------|------|-------------|
| `--json` | | Machine-readable JSON output |
| `--quiet` | | Suppress non-error output (exit code only) |
| `--dry-run` | | Validate command without side effects |

---

## Action categories

| Category | Buttons |
|----------|---------|
| `plain` | Default click only (no custom buttons) |
| `alert` | Acknowledge, Open, Silence |
| `job` | Acknowledge, Retry, Open |
| `deploy` | Open, Rollback, Acknowledge |

Run `notify listen` or `notify agent install` to receive action callbacks as structured JSON events.

Action events are written to `~/Library/Application\ Support/notify/actions.jsonl`.

---

## Local store

Notifications and actions are persisted to JSONL files:

```
~/Library/Application Support/notify/notifications.jsonl
~/Library/Application Support/notify/actions.jsonl
```

- Each line is a JSON object representing a notification or action event
- The store is append-only and rotated manually if needed
- Used by `list`, `get`, and `dismiss --thread` commands

---

## Exit codes

| Code | Name | Meaning |
|------|------|---------|
| `0` | success | Command completed successfully |
| `44` | notFound | Resource not found |
| `64` | usage | Usage error |
| `65` | invalidInput | Invalid input |
| `69` | permissionDenied | Permission denied |
| `70` | systemError | System error |
| `124` | timeout | Timeout |
| `130` | interrupted | Interrupted by user |

---

## Examples

### Status and permissions

```bash
# Check current permission state
notify status
notify status --json

# Request notification authorization
notify request-permission
notify request-permission --sound --badge --json
```

### Sending notifications

```bash
# Simple notification
notify send "Hello from the CLI!"

# With all options
notify send \
  --id deploy-api-prod \
  --title "Déploiement" \
  --subtitle "Backend API" \
  --body "Step 2/5: migrations" \
  --category deploy \
  --thread deploy-api-prod \
  --url "https://grafana.example/d/abc" \
  --sound default \
  --interruption-level active \
  --json

# Dry run (validate without sending)
notify send "Test" --dry-run --json
```

### Updating notifications

```bash
# Update an existing notification by its ID
notify update deploy-api-prod \
  --title "Déploiement terminé" \
  --body "OK en 3m42s"
```

### Dismissing notifications

```bash
# By ID
notify dismiss deploy-api-prod

# By thread group
notify dismiss --thread deploy-api-prod

# Dismiss all
notify dismiss --all

# Scope to pending or delivered only
notify dismiss --all --pending
notify dismiss --all --delivered
```

### Listing and inspecting

```bash
# List all notifications from the local store
notify list
notify list --json

# Filter by thread
notify list --thread deploy-api-prod

# Get a single notification
notify get deploy-api-prod --json
```

### Background listener

```bash
# Run listener in foreground (for testing)
notify listen

# Install as a background LaunchAgent
notify agent install

# Check status
notify agent status

# Remove
notify agent uninstall
```

### Test notification

```bash
# Quick smoke test
notify test

```


### Scripting with JSON

```bash
# Send and capture the notification ID
ID=$(notify send "Deploy started" --id deploy-web --json | jq -r '.id')

# Update later
notify update "$ID" --body "Deploy finished"

# Get the stored record
notify get "$ID" --json | jq '.data'
```

---

## Notes

- `notify` can only access notifications created by the same app identity (Notify.app bundle).
- `send` and `update` use the same `UNNotificationRequest` engine — sending with an existing identifier replaces the notification.
- Notifications require an active macOS user session. Behavior may be limited from headless/SSH/daemon contexts.
- The listener (`notify listen`) must have its app bundle in focus or be run via the LaunchAgent to receive action callbacks.

---

## Development

```bash
# Build
swift build

# Test
swift test

# Build for release
swift build -c release

# Build & install
make install
```

### Project structure

```
Sources/
  notify/
    Notify.swift           # Entry point & command configuration
    Commands/                 # CLI command implementations
    Notifications/            # Notification service, payload, store
    Support/                  # Utilities: output, errors, exit codes
    Schemas/                  # (reserved for future JSON schemas)
Tests/
  notifyTests/             # Unit tests
```

---

## Contributing

Contributions are welcome! Please open an issue or submit a pull request.

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/my-feature`)
3. Commit your changes (`git commit -am 'Add my feature'`)
4. Push to the branch (`git push origin feature/my-feature`)
5. Open a Pull Request

---

## License

MIT License. See [LICENSE](LICENSE) for details.
