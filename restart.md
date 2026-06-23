# Restart — resume cold

## What this is
Project Reminder: Mac + iPhone + Watch app that resurfaces your active projects on the wrist on a
repeating haptic interval (round-robin rotation). See `claude.md` / `context.md`.

## Current state (2026-06-23) — BUILD COMPLETE
- All three apps build into `.app` products (Mac + iOS sim + watch sim). `ReminderKit` 22 tests green.
- `Packages/DesignKit` provides the shared neumorphic-purple look; applied across all three apps.
- Mac authoring app (`MacBridge`/`MacContentView`/`ProjectEditor`) verified running.
- Built Mac `.app` copied to `build/ProjectReminderMac.app`.
- Contract frozen in `shared/SCHEMA.md`; coordination log in `shared/HANDOFF.md` (STATUS: CLEAR).
- Not yet done: git init/push to the GitHub remote (awaiting user OK); real-device haptic test;
  app icons; optional Watch complication.

## To resume
```bash
cd ~/Apps/ProjectReminder
xcodegen generate
swift test --package-path Packages/ReminderKit
xcodebuild -project ProjectReminder.xcodeproj -scheme ProjectReminderMac -destination 'platform=macOS' build
```
Then read `shared/STATUS.md` and the tail of `shared/HANDOFF.md` to see where the agents are.

## Where things live
- Shared core: `Packages/ReminderKit/Sources/ReminderKit/{Model,Rotation,Settings,Store,Sync}`
- Apps: `ProjectReminderMac/`, `ProjectReminder/` (iOS), `ProjectReminderWatch/`
- Coordination: `shared/{SCHEMA,HANDOFF,STATUS}.md`; protocol in `agents.md`
- Plan: `~/.claude/plans/buzzing-chasing-alpaca.md`

## Open follow-ups
- Real-device test of the interval haptic cadence (notifications) on a paired Watch.
- Weekly re-sign (free personal team, 7-day expiry).
- Future: `CloudKitTransport` behind `SyncTransport`; optional Watch complication; "suggest next
  action" idea (deferred — out of v1 scope).
