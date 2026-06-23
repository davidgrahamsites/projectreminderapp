# iOS Target — agents.md

## This target: Agent B
File domain: `ProjectReminder/**` (iOS).

## Depends on (read-only)
- `Packages/ReminderKit/` — `AppStore`, `WatchConnectivityTransport`, and views all import ReminderKit.
- `shared/SCHEMA.md` — frozen contract for types and protocols.

## Coordinates with
- **Agent A (ReminderKit/Mac):** Watch for HANDOFF entries announcing `SwiftDataReminderStore`
  and `LANTransport`. Wire them in per the TODO comments in `ProjectReminderApp.swift` and
  `ProjectReminder/Store/AppStore.swift`.
- **Agent C (Watch):** WatchConnectivity envelope format — both sides use `SyncEnvelope` JSON
  under the key `"envelope"` (Data) in the WCSession payload dict.

## Never edit
`project.yml`, `shared/SCHEMA.md`, or any file outside `ProjectReminder/`.
