# iOS Target — context.md

## Role
The iPhone app is the **bridge**, not the primary UI. Its two jobs:
1. Mirror the project list (editable on the go).
2. Relay sync between Mac (LAN) and Watch (WatchConnectivity).

## Sync relay diagram
```
Mac ←—— LANTransport ——→ iPhone ←—— WatchConnectivity ——→ Watch
```
Inbound from any transport is merged (LWW) and forwarded to the others.

## User-facing features
- Project list: add, edit, delete, reorder (rotation order = list order).
- Settings: reminder interval picker (feeds the Watch's notification cadence).

## Out of scope for iOS
- App Opener Hub data bus (iOS can't reach localhost 127.0.0.1 — Mac-only).
- Firing haptics / local notifications (Watch-only).
- iCloud sync (deferred; free personal team).
