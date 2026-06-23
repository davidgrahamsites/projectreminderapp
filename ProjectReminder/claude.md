# iOS Target — claude.md

## What this directory owns
All files under `ProjectReminder/` (iOS app target). Do NOT touch:
- `Packages/ReminderKit/**` (Agent A)
- `ProjectReminderMac/**` (Agent A)
- `ProjectReminderWatch/**` (Agent C)
- `project.yml`, `shared/SCHEMA.md` (Team Lead only)

## Key files
- `ProjectReminderApp.swift` — entry point; wires store + transports
- `Store/AppStore.swift` — `@Observable @MainActor` store; owns transport wiring + relay
- `Sync/WatchConnectivityTransport.swift` — WCSession `SyncTransport` conformer
- `Views/ProjectListView.swift` — list with add/edit/delete/reorder
- `Views/ProjectEditView.swift` — add/edit sheet
- `Views/SettingsView.swift` — interval picker

## How sync works
- User mutation → `AppStore.touch()` → `publish()` → all transports
- Inbound from transport A → `AppStore.receive()` → LWW merge → relay to other transports
- iPhone bridges Mac↔Watch: inbound from LAN relays to WC, inbound from WC relays to LAN

## Switching to SwiftDataReminderStore (Agent A)
When Agent A's HANDOFF says `SwiftDataReminderStore` is ready:
1. Change `AppStore` init to delegate storage to `SwiftDataReminderStore`.
2. Or replace `AppStore`'s `document`/`settings` vars with SwiftData-backed properties.
3. Transport wiring in `AppStore` stays unchanged.

## Wiring LANTransport (Agent A)
In `ProjectReminderApp.swift`, uncomment the `lanTransport` lines when Agent A's HANDOFF confirms `LANTransport` is in ReminderKit.
