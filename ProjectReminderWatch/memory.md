# ProjectReminderWatch — Memory (running decision log)

## 2026-06-23 — Phase 1 implementation

**WatchStore instead of InMemoryReminderStore**
`InMemoryReminderStore` lacks `@Observable`, so SwiftUI views would never re-render on data changes.
Created `WatchStore: @Observable @MainActor ReminderStoring` as a shim. Mirrors the same logic.
Switch to `SwiftDataReminderStore` at the `WatchStore()` call site once Agent A announces it.

**Lifecycle hook: scenePhase → .background**
Chosen over `onDisappear` because the Settings screen is a pushed NavigationStack child within the
same scene; its appearance triggers `onDisappear` on the list, which would advance the rotation
incorrectly. Background phase fires only on true app exit.

**WCSession message key: "syncEnvelope"**
Value: `Data` — JSON-encoded `SyncEnvelope` via `SyncEnvelope.encoded()`.
Both `updateApplicationContext` and `sendMessage` paths are handled.
Documented in HANDOFF.md for Agent B to implement the matching send side.

**Notification content**
Generic title/body — not personalized to current head — because the head project changes on every
dismiss, making any personalized content stale by next fire. Generic is always accurate.

**HapticScheduler as UNUserNotificationCenterDelegate**
When a notification fires while the app is foregrounded, we play `.notification` haptic directly
and suppress the banner (user is already looking at the list). System haptic fires automatically
when the notification delivers while the Watch screen is off.
