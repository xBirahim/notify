# Contributing to notify

Thank you for your interest in contributing! This document covers everything you need to get started.

## Requirements

- macOS 13 or later
- Swift 6.0+ (via Xcode 16+ or the Swift toolchain)
- `make` (included with Xcode Command Line Tools)

## Development setup

```bash
git clone https://github.com/xBirahim/notifyctl.git
cd notifyctl
make build
```

To install a development build locally:

```bash
make install
notify --version
```

## Running tests

```bash
make test
```

## Code style

- Swift 6.0 strict mode is enforced by `Package.swift` — the build will fail on concurrency violations
- Follow the existing patterns: one file per type, `Commands/` for CLI, `Notifications/` for domain logic, `Support/` for utilities
- No force-unwraps (`!`) except where the value is guaranteed by a prior guard
- Error handling must use `NotifyError` — never `fatalError` in reachable paths
- No comments explaining *what* the code does; only add one when the *why* is non-obvious

## Submitting changes

1. Fork the repository and create a branch from `main`
2. Make your changes with focused, atomic commits (one concern per commit)
3. Use [conventional commit](https://www.conventionalcommits.org/) prefixes: `feat:`, `fix:`, `docs:`, `chore:`, `refactor:`, `test:`
4. Ensure `make test` passes
5. Open a pull request with a clear description of *why* the change is needed

## Reporting bugs

Open an issue with:
- macOS version and Swift version (`swift --version`)
- The exact `notify` command that triggered the issue
- The full output (use `--json` for machine-readable context)
- Expected vs. actual behavior

## Feature requests

Open an issue describing the use case. Prefer concrete examples (e.g., an AI agent workflow) over abstract descriptions.

## Security issues

Please do **not** open a public issue for security vulnerabilities. See [SECURITY.md](SECURITY.md) instead.
