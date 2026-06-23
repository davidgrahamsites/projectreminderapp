# ProjectReminderWatch — Agents Coordination

Agent C owns `ProjectReminderWatch/**`. See root `agents.md` for the full loop protocol.

## Dependencies on Agent A
- Waiting for `SwiftDataReminderStore` (App Group `group.com.danielwang.projectreminder`).
- When available: replace `WatchStore()` in `ProjectReminderWatchApp.swift`.
- No other file changes needed — store is accessed only via `ReminderStoring` protocol.

## Dependencies on Agent B
- `WatchConnectivityReceiver` is ready on the Watch side.
- Agent B sends `SyncEnvelope` JSON as `Data` under key `"envelope"` (confirmed in B's HANDOFF):
  - Primary: `WCSession.default.updateApplicationContext(["envelope": data])`
  - Fallback: `WCSession.default.transferUserInfo(["envelope": data])`
- Watch side handles both `didReceiveApplicationContext` and `didReceiveUserInfo`.

## What I must NOT touch
`project.yml`, `shared/SCHEMA.md`, `Packages/ReminderKit/**`, `ProjectReminder/**`, `ProjectReminderMac/**`.
