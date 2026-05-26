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
