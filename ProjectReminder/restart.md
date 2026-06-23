# iOS Target — restart.md

## How to resume work on this target cold

1. Read `shared/STATUS.md` — stop if CONFLICT.
2. Read last 10 entries in `shared/HANDOFF.md` — adapt if Agent A or C changed the contract.
3. Read `shared/SCHEMA.md` for the frozen types.
4. Read `ProjectReminder/claude.md` (this directory) for file map.
5. Read `ProjectReminder/memory.md` for past decisions.

## Build commands
```bash
cd /Users/appleadmin/Apps/ProjectReminder
xcodegen generate
xcodebuild -project ProjectReminder.xcodeproj -scheme ProjectReminder \
  -destination 'platform=iOS Simulator,name=iPhone 17' build CODE_SIGNING_ALLOWED=NO
```

## Pending wiring (check HANDOFF first)
- LANTransport: uncomment two lines in `ProjectReminderApp.swift` when Agent A delivers it.
- SwiftDataReminderStore: update `AppStore` storage when Agent A delivers it.
