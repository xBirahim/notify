# notifyctl

`notifyctl` is a macOS CLI to send and manage native notifications with stable, scriptable output, action categories, and a local event store.

## Requirements

- macOS 13+
- Swift 6+

## Quickstart

```bash
swift build
swift run notifyctl --help
```

## Install on macOS (required for UserNotifications)

`UNUserNotificationCenter` requires an app bundle identity. Install `notifyctl` without `sudo`:

```bash
make install
export PATH="$HOME/.local/bin:$PATH"
notifyctl version --json
```

This creates:

- `~/.local/share/NotifyCtl.app` (bundled executable)
- `~/.local/bin/notifyctl` (launcher script)

Make sure `~/.local/bin` is in your `PATH` (add `export PATH="$HOME/.local/bin:$PATH"` to your `~/.zshrc`).

## Commands

| Command | Description |
|---|---|
| `status` | Show macOS notification permission state |
| `request-permission` | Request notification authorization |
| `send` | Send a notification |
| `update` | Update a notification (same engine as send) |
| `dismiss` | Dismiss by id, thread, or all |
| `list` | List notifications from local store |
| `get` | Get one notification by identifier |
| `test` | Send a test notification |
| `listen` | Long-running process for action callbacks |
| `agent` | Manage background listener LaunchAgent |
| `version` | Print version |

## Options

- `--id` — stable identifier (required for update, optional for send)
- `--title` / `--subtitle` / `--body` — notification content
- `--category` — `plain`, `alert`, `job`, or `deploy` (adds action buttons)
- `--thread` — macOS thread grouping (e.g. `deploy-api-prod`)
- `--url` — attached URL (passed in userInfo)
- `--sound` — `default` or `none`
- `--interruption-level` — `passive`, `active`, or `time-sensitive` (default: active)
- `--json` / `--quiet` / `--dry-run` — output control

## Examples

```bash
notifyctl status --json
notifyctl request-permission --sound --json
notifyctl send --id deploy-api-prod --title "Déploiement" --body "Step 2/5: migrations" --category deploy --thread deploy-api-prod --url "https://grafana.example/d/abc" --json
notifyctl send --id alert-cpu --title "CPU critique" --body "api-prod > 95%" --category alert --interruption-level time-sensitive
notifyctl update deploy-api-prod --title "Déploiement terminé" --body "OK en 3m42s"
notifyctl dismiss --thread deploy-api-prod
notifyctl dismiss --all
notifyctl list --json
notifyctl listen
notifyctl agent install
```

## Action categories

| Category | Buttons |
|---|---|
| `plain` | (default click only) |
| `alert` | Acquitter, Ouvrir, Silence |
| `job` | Acquitter, Relancer, Ouvrir |
| `deploy` | Ouvrir, Rollback, Acquitter |

Run `notifyctl listen` to receive action callbacks as structured JSON events.

## Local store

Notifications and actions are persisted to:

```
~/Library/Application Support/notifyctl/notifications.jsonl
~/Library/Application Support/notifyctl/actions.jsonl
```

## Notes

- `notifyctl` can only access notifications created by the same app identity.
- `send` and `update` use the same `UNNotificationRequest` engine — sending with an existing identifier replaces the notification.
- Notification behavior requires an active macOS user session.
- Behavior can be limited from headless/SSH/daemon contexts.
