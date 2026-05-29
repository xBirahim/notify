# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] — 2026-05-30

### Added
- `--wait` flag on `send` command for send-and-wait action button response
- `--user-info` option on `send` and `update` commands for arbitrary metadata entries
- `listen` command with graceful shutdown on SIGINT/SIGTERM
- `agent` subcommand with dry-run, JSON output, and structured error handling
- `NotificationListener` integration for capturing user interactions
- URL opening via `NSWorkspace` when user taps an OPEN button
- Action categories system (`plain`, `alert`, `job`, `deploy`) with predefined button sets
- Persistent local JSONL store at `~/Library/Application Support/notify/`
- Fallback storage path `~/.local/share/notify/` when App Support is unavailable
- `SKILL.md` — AI agent integration guide with workflow examples
- `--interruption-level` option (`passive`, `active`)

### Changed
- Renamed project from `notifyctl` to `notify`
- Renamed `message` field to `body` in the notification model
- Refactored `NotificationStatus` for cleaner state tracking
- Simplified `VersionCommand` output
- Improved bundle installation and LaunchServices registration
- Updated README with rich examples, real-world workflows, and exit codes reference

### Fixed
- Crash in `listen` command (`dispatchMain()` called on background thread)
- `NotifyCategory` raw values now match lowercase CLI input
- Fallback path added to `LocalStore` for robustness
- Permission errors now preserved and surfaced correctly

### Removed
- `time-sensitive` interruption level (requires special entitlements)

## [0.1.0] — 2026-05-18

### Added
- Initial MVP: `send`, `update`, `dismiss`, `list`, `get`, `status`, `request-permission`, `version` commands
- `NotificationService` wrapping `UNUserNotificationCenter`
- JSON envelope output (`ResultEnvelope`) for machine-readable responses
- Exit codes following BSD conventions (0, 44, 64, 65, 69, 70, 124, 130)
- App bundle structure required by `UNUserNotificationCenter`
- `make install` target creating `~/.local/share/Notify.app` bundle and `~/.local/bin/notify` launcher
- Swift 6.0 strict concurrency mode
