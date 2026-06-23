# ProjectReminderWatch — References

- `shared/SCHEMA.md` — frozen contract (types, rotation mechanic, store/sync protocols)
- `Packages/ReminderKit/Sources/ReminderKit/` — all types this target consumes
- `Packages/ReminderKit/Sources/ReminderKit/Rotation/RotationEngine.swift` — the round-robin logic
- `Packages/ReminderKit/Sources/ReminderKit/Store/ReminderStore.swift` — ReminderStoring protocol
- `Packages/ReminderKit/Sources/ReminderKit/Settings/ReminderSettings.swift` — ReminderInterval.presets
- `Packages/ReminderKit/Sources/ReminderKit/Sync/SyncTransport.swift` — SyncEnvelope shape
- `llm_memory/wiki/domains/watch-haptics.md` — notification strategy + lifecycle decisions
- Apple docs: UNUserNotificationCenter, UNTimeIntervalNotificationTrigger, WCSession, WKInterfaceDevice
