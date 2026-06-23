# References

## Internal
- Architectural template: `~/Apps/KetoMineralTracker` (SwiftUI + XcodeGen + shared package +
  WatchConnectivity + App Group; iOS+Watch).
- Multi-agent build methodology: `~/brain/multi-agent-coordination-plan.md` (the Karpathy loop:
  SCHEMA/HANDOFF/STATUS + Monitor watcher).
- LLM-memory-wiki convention: `~/Apps/KetoMineralTracker/llm_memory/`, `~/Apps/Trip Planner/llm_memory/`.
- App Opener Hub data bus: `~/Apps/App Opener/databus/SKILL.md` (`127.0.0.1:9800`).
- Build plan: `~/.claude/plans/buzzing-chasing-alpaca.md`.

## Apple platform docs (verify against current SDK)
- WatchConnectivity (`WCSession`) — phone↔watch transfer.
- Network framework (`NWListener`/`NWBrowser`) + Bonjour — LAN/cable peer discovery & transfer.
- `UNUserNotificationCenter` + `UNTimeIntervalNotificationTrigger` (repeating, >= 60s) — watch haptics.
- SwiftData + App Group container — per-device persistence shared with extensions.
- WidgetKit complications (watchOS) — optional head-project glance.
- CloudKit / `NSPersistentCloudKitContainer` — deferred (needs paid account).

## Constraints
- Free personal team: 7-day app expiry; CloudKit & some entitlements unavailable.
- XcodeGen: regenerate `.xcodeproj` after any file/target change.
