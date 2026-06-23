# Memory — running decision log

Newest first. Each entry: decision + rationale.

## 2026-06-23 — Shared DesignKit for one consistent look (4th "agent" / design phase)
Added `Packages/DesignKit` (neumorphic-purple SwiftUI tokens + ProjectCard/ProjectRow signature),
linked into all three targets, and restyled Mac/iOS/watch to match. Overall look only (per user),
from a reference UI kit. Built the real macOS authoring UI here too (was a stub). Rationale: the three
apps must feel like one product. Note: the background build/design agents repeatedly returned idle
without output, so the Team Lead executed their briefs directly — more reliable for completion.

## 2026-06-23 — Rotation = simple queue rotation
Head shown on top; on dismiss the head moves to tail (`RotationEngine.advance`). Modeled as a pure
value transform in ReminderKit so all three platforms agree from the same `ReminderDocument`.
Rationale: matches the spec exactly ("next item to top, closed item to bottom") and is trivially
unit-testable.

## 2026-06-23 — Local-first sync behind a `SyncTransport` protocol
Mac↔iPhone via Bonjour `LANTransport`; iPhone↔Watch via WatchConnectivity. LWW merge on
`ReminderDocument.version`. A `CloudKitTransport` can be added later without touching callers.
Rationale: user wants Wi-Fi/cable now, no cloud dependency; free team can't use CloudKit anyway.

## 2026-06-23 — Interval haptic via repeating local notifications
watchOS has no free arbitrary background timer; `UNUserNotificationCenter` repeating triggers
(>= 60s) deliver the haptic and open the app to the rotated list.

## 2026-06-23 — One XcodeGen project, three targets, shared ReminderKit package
Mirrors the proven `~/Apps/KetoMineralTracker` setup. Adds a macOS target and a LAN transport.
ReminderKit stays UI-free and unit-tested; UI binds to `ReminderStoring`.

## 2026-06-23 — Hub data bus only on Mac
iOS/watch can't reach `127.0.0.1:9800`. Only the Mac app posts (fire-and-forget) on sync/export.

## 2026-06-23 — No LLM in v1
"Karpathy" refers to the `llm_memory/wiki` + behavioral-guidelines methodology and the brain's
multi-agent coordination loop — not an LLM integration. "Suggest next action" deferred.
