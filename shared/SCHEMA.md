# Shared Contract — FROZEN (only the Team Lead edits this)

Every agent implements against this. To change it: stop, message the Lead, the Lead edits here,
logs a HANDOFF entry, and clears STATUS. A/B/C must NEVER edit this file.

Source of truth in code: `Packages/ReminderKit/Sources/ReminderKit/`.

## Bundle / identity
- Bundle base: `com.danielwang.projectreminder`
  - Mac `…​.mac` · iOS `…​projectreminder` · Watch `…​.watchkitapp`
- App Group: `group.com.danielwang.projectreminder`
- Bonjour service type: `_projreminder._tcp`
- Deployment: iOS 17 / watchOS 10 / macOS 14

## Types (ReminderKit public API — do not rename fields)

```swift
struct Project: Identifiable, Codable, Equatable, Hashable, Sendable {
    let id: UUID
    var title: String
    var notes: String
    var createdAt: Date
    var lastModified: Date
}

struct ReminderDocument: Codable, Equatable, Sendable {
    var projects: [Project]      // projects[0] == rotation head (shown on top)
    var version: Int             // monotonic; drives last-writer-wins
    var lastModified: Date
    var head: Project? { get }
    static func merged(_ a: ReminderDocument, _ b: ReminderDocument) -> ReminderDocument
}

enum ReminderInterval: Codable, Equatable, Hashable, Sendable {
    case minutes(Int); case hours(Int)
    var seconds: TimeInterval { get }       // >= 60, feeds UNTimeIntervalNotificationTrigger
    static let presets: [ReminderInterval]
    var label: String { get }
}
struct ReminderSettings: Codable, Equatable, Sendable { var interval: ReminderInterval }

enum RotationEngine {
    static func head(of: ReminderDocument) -> Project?
    static func advance(_ doc: ReminderDocument, now: Date = Date()) -> ReminderDocument
}
```

## Rotation mechanic (the whole point of the app)
- The Watch list shows `document.projects[0]` on top.
- When the Watch list is **dismissed/closed**, call `store.advanceRotation()` →
  `RotationEngine.advance` moves the head to the tail and bumps `version`.
- `[A,B,C,D]` → show A → dismiss → `[B,C,D,A]` → next show B. No-op for 0–1 projects.

## Store API (UI binds to this protocol)
```swift
@MainActor protocol ReminderStoring: AnyObject {
    var document: ReminderDocument { get }
    var settings: ReminderSettings { get }
    func add(_:); func update(_:); func delete(id:); func move(from:to:)
    func advanceRotation()
    func setInterval(_:)
    func apply(_ envelope: SyncEnvelope)   // LWW merge of inbound peer state
}
```
- `InMemoryReminderStore` ships now (tested). Agent A adds `SwiftDataReminderStore`
  (App Group container) behind the SAME protocol. UI must depend only on `ReminderStoring`.

## Sync seam (local now, iCloud later — same protocol)
```swift
struct SyncEnvelope: Codable, Equatable, Sendable {
    var document: ReminderDocument
    var settings: ReminderSettings
    var deviceID: String
    var sentAt: Date
}
protocol SyncTransport: AnyObject {
    static var serviceType: String { get }   // default "_projreminder._tcp"
    func publish(_ envelope: SyncEnvelope)
    var incoming: AsyncStream<SyncEnvelope> { get }
}
```
- Agent A: `LANTransport` (Network framework NWListener/NWBrowser, Bonjour) for Mac↔iPhone.
- Agent B: `WatchConnectivityTransport` (WCSession) for iPhone↔Watch.
  - **WC payload key is `"envelope"`** (canonical): dict `["envelope": SyncEnvelope.encoded() as Data]`,
    sent via `updateApplicationContext` (primary) + `transferUserInfo` (fallback); receivers handle
    both `didReceiveApplicationContext` and `didReceiveUserInfo`. Do not rename this key.
- Inbound envelopes are merged via `ReminderDocument.merged` (LWW on version, then date).
- A future `CloudKitTransport` conforms to the same protocol — do not bake cloud assumptions
  into callers.

## Ownership (disjoint file domains — no shared-file edits)
- **Agent A:** `Packages/ReminderKit/**`, `ProjectReminderMac/**`
- **Agent B:** `ProjectReminder/**` (iOS)
- **Agent C:** `ProjectReminderWatch/**`
- **Team Lead only:** `project.yml`, `shared/SCHEMA.md`
- Run `xcodegen generate` after adding/removing files.
