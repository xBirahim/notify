---
name: notify
description: Use when you need to send macOS native notifications to the user, ask for confirmation via interactive action buttons, update existing notifications, or check notification permission status. Do NOT use for CI/CD pipelines or headless environments — this tool only works on macOS with an active user session.
---

# notify — macOS Native Notifications for AI Agents

`notify` is a CLI tool that sends and manages macOS native notifications. As an AI agent, you can use it to keep the user informed during long-running tasks, ask for decisions via action buttons, and report results — all without cluttering the terminal.

## Prerequisites

Before using `notify`, verify these are in place:

```bash
# 1. Check if notify is installed
which notify 2>/dev/null || echo "not installed"

# 2. Check notification permission status
notify status --json

# 3. If not authorized, request permission (run once per machine)
notify request-permission --sound --badge
```

If `notify` is not installed or needs updating (e.g. after pulling new changes), rebuild and install:

```bash
make install
```

> **Note**: If `send --wait` produces no output, first run `make install` — the installed binary may be outdated.

## Quick Reference

| Command | Purpose | When to use |
|---|---|---|
| `notify status` | Check permission state | Before first send |
| `notify request-permission` | Grant notification access | First-time setup |
| `notify send` | Send a new notification | Inform user, ask confirmation |
| `notify send --wait` | Send + wait for button press | Get user decision in one command |
| `notify update` | Replace an existing notification | Update progress → result |
| `notify dismiss` | Remove notifications | Clean up after done |
| `notify list` | View stored notifications | Debug / audit |
| `notify listen` | Watch for action button responses | Wait for user decision |
| `notify test` | Send a test notification | Verify setup |

## Sending Notifications

The most common operation. Always include `--json` when you want a parseable response.

### Minimal notification

```bash
notify send "Task complete"
```

### Structured notification

```bash
notify send \
  --id build-site \
  --title "Build complete" \
  --subtitle "site-generator / production" \
  --body "Generated 342 pages in 1.2s" \
  --category plain \
  --json
```

### Notification with error state

```bash
notify send \
  --id deploy-api-failed \
  --title "Operation failed" \
  --body "Step 3/4: migration timed out" \
  --interruption-level active \
  --url "https://logs.example.com/deploy/1842" \
  --json
```

### Updating progress to completion

```bash
# Initial progress
notify send \
  --id build-site \
  --title "Building site" \
  --body "Step 1/4: fetching content..." \
  --category plain \
  --json

# After step completes
notify update build-site \
  --body "Step 2/4: generating pages..." \
  --json

# Final result
notify update build-site \
  --title "Build complete" \
  --body "Generated 342 pages in 1.2s" \
  --sound default \
  --json
```

## JSON Output Format

Machine-readable responses use a standard envelope:

```json
{
  "id": "build-site",
  "command": "send",
  "status": "delivered",
  "data": {},
  "error": null
}
```

On error:

```json
{
  "id": "build-site",
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

Parse with `jq` or any JSON library:

```bash
# Check status from a send
STATUS=$(notify send --id task-1 --title "Task" --body "Running" --json | jq -r '.status')
```

## Asking for User Confirmation (Action Buttons)

This is the most powerful feature for AI agents. Use notification *categories* to attach interactive buttons, then use `notify send --wait` to capture the user's choice in a single command.

### Available Categories

| Category | Buttons | Use case |
|---|---|---|
| `plain` | None | Pure info, no response needed |
| `alert` | ACK, OPEN, SILENCE | Incident or alert that needs acknowledgment |
| `job` | ACK, RETRY, OPEN | Background job the user can retry |
| `deploy` | OPEN, ROLLBACK, ACK | Operation the user can approve or rollback |

### Pattern: Ask → Wait → Act

With `notify send --wait`, the command blocks until the user clicks a button, then outputs the action. No separate `notify listen` process needed.

```bash
# Step 1: Send and wait for the user's response
ACTION=$(notify send \
  --id confirm-deploy \
  --title "Deploy to production?" \
  --body "Release v2.1.0 to production? 12 commits, 3 migrations." \
  --category deploy \
  --thread deploy-confirm \
  --url "https://github.com/org/repo/releases/v2.1.0" \
  --interruption-level active \
  --wait --wait-timeout 300 \
  --json 2>/dev/null | jq -r '.data.action // "timeout"')

# Step 2: Act on the response
case "$ACTION" in
  "OPEN")     echo "User opened the URL — continuing" ;;
  "ROLLBACK") echo "User requested rollback — aborting" ;;
  "ACK")      echo "User acknowledged — continuing" ;;
  "timeout")  echo "No response within 5 minutes — aborting" ;;
  *)          echo "Unknown action ($ACTION) — continuing" ;;
esac
```

## Workflows for AI Agents

### Workflow 1: Progress notifications during a long task

Use when your task takes more than a few seconds. Send progressive updates so the user knows you're still working.

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
# ... do work ...

notify update "$TASK_ID" \
  --title "Build complete" \
  --body "Generated 342 pages in 1.2s" \
  --sound default \
  --json
```

### Workflow 2: Ask the user for a decision

Use when the agent needs human input before proceeding. `send --wait` blocks until the user clicks a button (or timeout), then returns the action immediately.

```bash
# Ask user to confirm a destructive operation
RESPONSE=$(notify send \
  --id cleanup-db \
  --title "Cleanup old records?" \
  --body "Delete 1,204 stale records from the database? This cannot be undone." \
  --category job \
  --thread cleanup \
  --wait --wait-timeout 120 \
  --json 2>/dev/null | jq -r '.data.action // "timeout"')

if [ "$RESPONSE" = "ACK" ] || [ "$RESPONSE" = "OPEN" ]; then
  notify update cleanup-db --title "Cleaning up..." --body "Removing 1,204 records..." --json
  # ... perform cleanup ...
  notify update cleanup-db --title "Cleanup complete" --body "Removed 1,204 records in 3.2s" --sound default --json
elif [ "$RESPONSE" = "RETRY" ]; then
  notify update cleanup-db --body "Operation retried — reviewing data first" --json
  # ... re-evaluate ...
elif [ "$RESPONSE" = "timeout" ]; then
  notify update cleanup-db --title "Cleanup skipped" --body "No response received — operation cancelled" --json
fi
```

### Workflow 3: Report task result

After completing a task, replace the progress notification with a clear result notification.

```bash
RESULT_ID="backup-db-$(date +%s)"

notify send \
  --id "$RESULT_ID" \
  --title "Starting backup" \
  --body "Backing up production database..." \
  --category plain \
  --thread "$RESULT_ID" \
  --json

# ... perform backup ...
BACKUP_SIZE="2.4 GB"
DURATION="47s"

if [ $? -eq 0 ]; then
  notify update "$RESULT_ID" \
    --title "Backup complete" \
    --body "Database backed up successfully (${BACKUP_SIZE}, ${DURATION})" \
    --sound default \
    --json
else
  notify update "$RESULT_ID" \
    --title "Backup failed" \
    --body "Database backup failed after ${DURATION}" \
    --interruption-level active \
    --json
fi
```

## Categories and Buttons (Reference)

| Category | Buttons | Behavior |
|---|---|---|
| `plain` | *(none)* | Passive notification, no interaction |
| `alert` | ACK, OPEN, SILENCE | User can acknowledge, open URL, or silence |
| `job` | ACK, RETRY, OPEN | User can acknowledge, retry the job, or open URL |
| `deploy` | OPEN, ROLLBACK, ACK | User can open URL, rollback, or acknowledge |

When the user clicks the notification body or the OPEN button, `notify` opens the notification's `--url` if provided.

## Error Handling

Always check the exit code or parse `--json` output:

```bash
OUTPUT=$(notify send --id task --title "Task" --body "Running" --json 2>&1)
STATUS=$(echo "$OUTPUT" | jq -r '.status // "error"')

if [ "$STATUS" = "error" ]; then
  CODE=$(echo "$OUTPUT" | jq -r '.error.code')
  echo "Notification failed: $CODE"
  # Handle: "permission_denied" → request-permission, "invalid_input" → fix args, etc.
fi
```

Exit codes: `0` success, `44` not found, `64` usage, `65` invalid input, `69` permission denied, `70` system error.

## Listen Mode (Background Listener)

For most interactive scripts, use `notify send --wait` (see above) — it blocks until the user responds, no separate listener needed.

For non‑blocking workflows (send a notification, continue working, check response later), install the background LaunchAgent:

```bash
notify agent install
```

The agent runs `notify listen` in the background and logs every action to `~/Library/Logs/notify/listener.log`. You can poll or tail this file to capture responses.

To stop the agent:
```bash
notify agent uninstall
```
