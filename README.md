# Project Reminder

Keep the projects you're actively working on **fresh in your mind**. Three SwiftUI apps —
**Mac**, **iPhone**, and **Apple Watch** — that resurface your projects on your wrist on a
repeating haptic interval. The Watch is the point: at your chosen interval it taps you and shows a
scrollable list with one project rotated to the top; once dismissed, that project drops to the
bottom so the next reminder promotes the next one (round-robin).

## Apps
- **Mac** (`ProjectReminderMac`) — where you set up and edit projects, and the reminder interval.
- **iPhone** (`ProjectReminder`) — carries the list on the go; bridges Mac ↔ Watch.
- **Watch** (`ProjectReminderWatch`) — the main surface: rotating list, interval haptics, and a
  watch-face complication showing the current project.

## Architecture
- **SwiftUI**, three app targets + two local packages, one XcodeGen project (`project.yml`).
- `Packages/ReminderKit/` — UI-free core: `RotationEngine` (the round-robin), `SwiftDataReminderStore`
  (App Group), and a `SyncTransport` seam: `LANTransport` (Bonjour, Mac↔iPhone) +
  `WatchConnectivityTransport` (iPhone↔Watch). CloudKit-ready for later. 22 unit tests.
- `Packages/DesignKit/` — shared neumorphic-purple look (`ProjectCard`/`ProjectRow` signature),
  applied across all three apps so they feel like one product.
- Sync is **local-first** (LAN / cable / WatchConnectivity); last-writer-wins on `ReminderDocument.version`.

## Build & run
```bash
brew install xcodegen        # one-time
cd ~/Apps/ProjectReminder
xcodegen generate            # regenerate ProjectReminder.xcodeproj
swift test --package-path Packages/ReminderKit          # 22 tests

# Build any target (simulator, no signing):
xcodebuild -project ProjectReminder.xcodeproj -scheme ProjectReminderMac   -destination 'platform=macOS' build
xcodebuild -project ProjectReminder.xcodeproj -scheme ProjectReminder      -destination 'platform=iOS Simulator,name=iPhone 17' build
xcodebuild -project ProjectReminder.xcodeproj -scheme ProjectReminderWatch -destination 'platform=watchOS Simulator,name=Apple Watch Series 11 (46mm)' build
```
Always run `xcodegen generate` after adding/removing files. `.xcodeproj` is gitignored (regenerated).

## Run on your devices (free personal team)
1. `open ProjectReminder.xcodeproj`
2. Select each target → Signing & Capabilities → set your **Team** (auto-managed bundle ids).
3. Pick your iPhone/Watch and Run. Note: apps from a free personal team **expire after 7 days** —
   re-run from Xcode to re-sign. CloudKit is unavailable on the free tier (sync stays local).

## Verified
All three apps build into `.app` products **and launch** (Mac/iOS/watch confirmed running). 22
ReminderKit tests pass. See `restart.md` for current state and `agents.md` for how this was built
(a multi-agent "Karpathy loop": `shared/SCHEMA.md` contract + `HANDOFF.md`/`STATUS.md`).

## Known manual steps
- **The interval haptic** must be validated on a **physical** Apple Watch — simulators don't deliver
  real wrist-tap timing for `UNUserNotificationCenter` repeating triggers.
- App icons are generated; swap in your own art under each target's `Assets.xcassets/AppIcon.appiconset`.

## Docs
`claude.md` (overview), `context.md` (why), `design.md` (look), `memory.md` (decisions),
`restart.md` (resume), `references.md`, `agents.md`, and `llm_memory/wiki/`.
