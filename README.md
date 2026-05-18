# notifyctl

`notifyctl` is a macOS CLI to send and manage local notifications with stable, scriptable output.

## Requirements

- macOS 13+
- Swift 6+

## Quickstart

```bash
swift build
swift run notifyctl --help
```

## Install on macOS (required for UserNotifications)

`UNUserNotificationCenter` requires an app bundle identity. Install `notifyctl` through a `.app` wrapper:

```bash
make install-app
sudo make install-link
notifyctl version --json
```

This creates:

- `/Applications/NotifyCtl.app`
- `/usr/local/bin/notifyctl` (symlink to app executable, via `install-link`)

## Implemented MVP commands

- `status`
- `request-permission`
- `send`
- `dismiss`
- `list`
- `update`
- `get`
- `test`
- `version`

## Examples

```bash
notifyctl status --json
notifyctl request-permission --sound --json
notifyctl send --id build-123 --title "CI" --message "Build terminé" --json
notifyctl update build-123 --message "Build terminé avec succès" --level success --json
notifyctl dismiss build-123 --json
notifyctl list --json
```

## Notes

- `notifyctl` can only access notifications created by the same app identity.
- `update` is implemented as `dismiss + send` using the same identifier.
- Notification behavior requires an active macOS user session.
- Behavior can be limited from headless/SSH/daemon contexts.
