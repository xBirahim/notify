# Security Policy

## Supported versions

| Version | Supported |
|---------|-----------|
| 0.2.x   | Yes       |
| < 0.2   | No        |

## Reporting a vulnerability

Please **do not** open a public GitHub issue for security vulnerabilities.

To report a vulnerability, open a [GitHub Security Advisory](../../security/advisories/new) for this repository. You will receive a response within 7 days.

Include:
- A description of the vulnerability and its potential impact
- Steps to reproduce
- macOS version and `notify` version (`notify version --json`)
- Any suggested fix, if you have one

## Security model

`notify` is a local-only macOS tool with no network communication:

- All data is stored in `~/Library/Application Support/notify/` (plain JSONL, user-readable by design)
- No credentials, tokens, or sensitive data are stored
- The tool runs entirely under the invoking user's privileges — no elevation, no setuid
- URLs are opened via `NSWorkspace.shared.open()` only on explicit user action (button tap)
- The LaunchAgent background listener (`agent install`) runs under the user session only
