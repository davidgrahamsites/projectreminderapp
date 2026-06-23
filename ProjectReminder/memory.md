# iOS Target — memory.md

## Key decisions

### @Observable AppStore owns transport wiring (2026-06-23)
Rather than a separate SyncCoordinator, `AppStore` owns the transport list and relay logic.
**Why**: fewer moving parts; all `@MainActor`-isolated state in one place; no callback/observer plumbing.

### updateApplicationContext over transferUserInfo as primary (2026-06-23)
WCSession `updateApplicationContext` is used first because `SyncEnvelope` is full-state LWW — only the latest snapshot matters. `transferUserInfo` is the fallback (reliable queue) for when context call throws.

### InMemoryReminderStore replaced by AppStore (2026-06-23)
The Phase-0 stub used `InMemoryReminderStore` directly. Agent B replaced it with `AppStore` which adds `@Observable` observation and transport wiring on top of the same logic.

### LANTransport stub commented out (2026-06-23)
Two `// TODO` comments in `ProjectReminderApp.swift` mark where to add the LAN transport when Agent A delivers `LANTransport` in ReminderKit.
