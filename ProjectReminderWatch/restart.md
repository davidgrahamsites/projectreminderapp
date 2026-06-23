# ProjectReminderWatch — Restart Guide

Read this to resume cold after a context break.

## What exists
All Watch code lives in `ProjectReminderWatch/`. The target builds against `watchOS 10`.
Current store is `WatchStore` (an `@Observable` shim). Once Agent A's HANDOFF says
`SwiftDataReminderStore` is available, change the one `WatchStore()` call in
`ProjectReminderWatchApp.swift` to the SwiftData store. Nothing else changes.

## Pending coordination with Agent B
Agent B (iOS) must send `SyncEnvelope` JSON as `Data` under key `"syncEnvelope"` via either
`updateApplicationContext` or `sendMessage` on `WCSession`. Watch side is ready to receive.
Check Agent B's HANDOFF entries for confirmation before testing end-to-end sync.

## Build
```bash
xcodegen generate
xcodebuild -project ProjectReminder.xcodeproj \
  -scheme ProjectReminderWatch \
  -destination 'platform=watchOS Simulator,name=Apple Watch Series 11 (46mm)' \
  build CODE_SIGNING_ALLOWED=NO
swift test --package-path Packages/ReminderKit   # must stay green
```

## Key invariants
- `document.projects[0]` is always the head shown on top.
- `store.advanceRotation()` is called exactly once per app dismissal (scenePhase → .background).
- Notifications repeat at `settings.interval.seconds` via `UNTimeIntervalNotificationTrigger`.
- Rescheduling happens: on first launch, on interval change (SettingsView), on each dismiss.
