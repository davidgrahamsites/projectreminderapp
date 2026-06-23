# HANDOFF LOG

Append-only. Every agent writes an entry after each meaningful change. Newest at the bottom.
Before claiming any task: read STATUS.md (stop if CONFLICT) and the last 10 entries here.

**Entry format**
```
## [TIMESTAMP] Agent X (domain)
- Changed: <what>
- Affects: <which other agents/domains, or "none">
- SCHEMA.md updated: yes/no
- Others must: <action, or "nothing">
```

---

## [2026-06-23] Team Lead — Phase 0 complete
- Changed: Scaffolded repo. ReminderKit package built (Model, RotationEngine + 6 passing tests,
  ReminderSettings, InMemoryReminderStore, SyncEnvelope/SyncTransport seam). project.yml with 3
  targets generates; ProjectReminderMac builds. App stubs in place for all 3 targets.
- Affects: all agents — this is your starting contract.
- SCHEMA.md updated: yes (frozen).
- Others must: implement against shared/SCHEMA.md; depend only on ReminderStoring/SyncTransport;
  never edit project.yml or SCHEMA.md (message the Lead instead).

## [2026-06-23] Agent B — iOS bridge app complete

- Changed: Replaced Phase-0 stub in `ProjectReminder/` with the full iOS bridge app:
  - `Store/AppStore.swift` — `@Observable @MainActor` store; owns transport wiring + Mac↔Watch relay
  - `Sync/WatchConnectivityTransport.swift` — `SyncTransport` via WCSession; iPhone-side delegate
  - `Views/ProjectListView.swift` — add / edit / delete / reorder, bound to `ReminderStoring`
  - `Views/ProjectEditView.swift` — add/edit sheet
  - `Views/SettingsView.swift` — interval picker using `ReminderInterval.presets`
  - `ProjectReminderApp.swift` — wires store + transports; requests notification permission
  - Six module docs created in `ProjectReminder/`
- Affects: Agent C (Watch) must use the same WCSession envelope format (see below)
- SCHEMA.md updated: no
- Others must:
  - **Agent C**: Send/receive `SyncEnvelope` JSON encoded as `Data` under the key `"envelope"`
    in the WCSession payload dict (both `updateApplicationContext` and `transferUserInfo`).
    Agent B (iPhone) decodes the same key on both `didReceiveApplicationContext` and
    `didReceiveUserInfo` delegate callbacks.
  - **Agent A**: When `LANTransport` is ready in ReminderKit, uncomment two lines in
    `ProjectReminder/ProjectReminderApp.swift` marked `// LANTransport (Agent A, ReminderKit)`.
    When `SwiftDataReminderStore` is ready, update `AppStore` storage as described in
    `ProjectReminder/claude.md`.

### WatchConnectivity message contract (for Agent C)
```
WCSession payload dict:  { "envelope": <Data> }
Encoding:  JSONEncoder().encode(SyncEnvelope)   (SyncEnvelope.encoded())
Decoding:  JSONDecoder().decode(SyncEnvelope, from: data)  (SyncEnvelope.decoded(from:))
Primary channel:  session.updateApplicationContext(payload)
Fallback channel: session.transferUserInfo(payload)  (when context call throws)
```
Both sides must listen on `didReceiveApplicationContext` AND `didReceiveUserInfo`.

## [2026-06-23] Agent C — watchOS Phase 1 complete

- Changed: Replaced Phase-0 Watch stub with full implementation in `ProjectReminderWatch/`:
  - `WatchStore.swift` — `@Observable @MainActor` ReminderStoring shim (SwiftUI-reactive;
    mirrors InMemoryReminderStore; replace with SwiftDataReminderStore at the call site when A lands it)
  - `HapticScheduler.swift` — UNUserNotificationCenter scheduling + UNUserNotificationCenterDelegate;
    `UNTimeIntervalNotificationTrigger(repeats: true)`; plays `WKInterfaceDevice.current().play(.notification)`
    when notification fires while app is frontmost
  - `RotatingListView.swift` — scrollable list, head (index 0) pinned/emphasized in "Now" section,
    rest in "Up Next"; NavigationStack with Settings toolbar item; empty-state overlay
  - `SettingsView.swift` — interval picker using `ReminderInterval.presets`; calls
    `store.setInterval` + `scheduler.schedule` on tap
  - `WatchConnectivityReceiver.swift` — WCSession delegate; reads key `"envelope"` (matching B's
    contract) from both `didReceiveApplicationContext` and `didReceiveUserInfo`
  - `ProjectReminderWatchApp.swift` — wires all three above; scenePhase → .background hook calls
    `store.advanceRotation()` then reschedules; `.task` does one-time auth + WCSession activation
  - Six module docs (`claude.md context.md memory.md restart.md references.md agents.md`)
  - `llm_memory/wiki/domains/watch-haptics.md` — full rationale for notification strategy and
    scenePhase lifecycle hook including alternatives table and hidden assumptions
- Affects: Agent A (store switch), Agent B (WCSession key confirmation)
- SCHEMA.md updated: no
- Others must:
  - **Agent A**: When `SwiftDataReminderStore` is ready, announce in HANDOFF. Watch only needs
    to change `WatchStore()` → `SwiftDataReminderStore(...)` in `ProjectReminderWatchApp.swift`.
  - **Agent B**: Confirmed — Watch side now reads key `"envelope"` from both
    `updateApplicationContext` and `transferUserInfo`. B's existing implementation matches.

### Lifecycle hook for advance-on-dismiss
**`scenePhase → .background`** on the App scene's `.onChange(of:)`. Fires when the user presses
the Digital Crown or swipes up. Does NOT fire on navigation to SettingsView within the app.
See `llm_memory/wiki/domains/watch-haptics.md` for full rationale.

### WCSession keys (Watch receives)
```
Key:   "envelope"
Value: Data  (JSON-encoded SyncEnvelope, via SyncEnvelope.encoded()/decoded(from:))
Channels: didReceiveApplicationContext (primary), didReceiveUserInfo (fallback)
```

## [2026-06-23] Team Lead (Monitor) — WC key drift reconciled
- Changed: Pinned the WatchConnectivity payload key as canonical `"envelope"` in shared/SCHEMA.md
  (Sync seam). B and C code already agree on `"envelope"` (B→C alignment happened via the loop);
  this just freezes it so it can't regress. Note: ProjectReminderWatch/CLAUDE.md still says
  "syncEnvelope" in prose — Agent C should fix that doc line (code is correct).
- Affects: B, C (no code change needed — already aligned).
- SCHEMA.md updated: yes (key pinned; Lead).
- Others must: keep WC payload key = "envelope". Agent A still owes SwiftDataReminderStore +
  LANTransport; B and C run on fallback stores until then.

## [2026-06-23] Team Lead — integration fix: ReminderKit tests green
- Changed: Agent A's `SwiftDataStoreTests` accessed the @MainActor-isolated store from a
  nonisolated XCTestCase (93 compile errors). Marked the test class `@MainActor`. All 22 ReminderKit
  tests now pass (RotationEngine 6 + SwiftDataStore 9 + SyncEnvelope 7).
- Affects: Agent A (tests green). Mac app still a STUB.
- SCHEMA.md updated: no.
- Others must: nothing. Folding the Mac authoring UI into the Design pass (Agent D).

## [2026-06-23] Team Lead — design phase + final integration COMPLETE
- Changed: Built `Packages/DesignKit/` (Theme + Components: NeumorphicSurface, AccentButtonStyle,
  InitialBadge, ProjectRow, ProjectCard). Linked it into all 3 targets (project.yml). Built the real
  macOS authoring UI (MacBridge + MacContentView + ProjectEditor; SwiftDataReminderStore + LANTransport
  + App Opener Hub). Restyled iOS (ProjectListView/SettingsView) and watch (RotatingListView/SettingsView)
  to match. (The background design agent returned idle without output, so the Lead executed Agent D's brief.)
- Verified: `swift test` 22 green; ProjectReminderMac (macOS), ProjectReminder (iPhone 17 sim),
  ProjectReminderWatch (Apple Watch S11 sim) all BUILD SUCCEEDED; Mac .app launched and rendered.
- SCHEMA.md updated: no. STATUS: CLEAR — build complete.
