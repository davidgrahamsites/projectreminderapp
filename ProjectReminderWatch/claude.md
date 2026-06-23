# ProjectReminderWatch — Claude.md

Agent C owns all files under `ProjectReminderWatch/`. Do not touch other targets.

## File inventory
- `ProjectReminderWatchApp.swift` — app entry, scenePhase hook, bootstraps scheduler + receiver
- `WatchStore.swift` — @Observable ReminderStoring shim (replace with SwiftDataReminderStore later)
- `RotatingListView.swift` — main list UI (head emphasized, Settings nav)
- `HapticScheduler.swift` — UNUserNotificationCenter scheduling + delegate
- `SettingsView.swift` — interval picker
- `WatchConnectivityReceiver.swift` — WCSession delegate, decodes "syncEnvelope" key

## Key constraint
Never edit `project.yml`, `shared/SCHEMA.md`, or files outside `ProjectReminderWatch/`.
Run `xcodegen generate` and rebuild after adding/removing files.

## Switch-to-SwiftData
In `ProjectReminderWatchApp.swift`, replace `WatchStore()` with `SwiftDataReminderStore(...)` once
Agent A's HANDOFF announces it's ready. No other file needs to change.
