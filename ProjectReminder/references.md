# iOS Target — references.md

## WatchConnectivity pattern
`~/Apps/KetoMineralTracker/Packages/MineralKit/Sources/MineralKit/Sync/ConnectivitySyncer.swift`
— NSObject WCSessionDelegate, `transferUserInfo`, iOS `sessionDidDeactivate` reactivation.

## SyncTransport protocol
`Packages/ReminderKit/Sources/ReminderKit/Sync/SyncTransport.swift`

## SyncEnvelope (wire format)
`SyncEnvelope` is JSON-encoded. WCSession payload key: `"envelope"` (Data).
Agent C's WatchConnectivity code must use the same key and encoding.

## SwiftUI @Observable (iOS 17+)
https://developer.apple.com/documentation/Observation
`@Observable @MainActor` classes work with `@State` in `App`/`Scene`/`View`.

## WCSession docs
`updateApplicationContext` — overwrites; Watch receives on next activation.
`transferUserInfo` — reliable, queued, FIFO delivery regardless of Watch state.
