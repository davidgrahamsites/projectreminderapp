# memory
- 2026-06-23: Reads `SharedHeadState` (App-Group UserDefaults) rather than SwiftData — the watch app
  writes the head title + calls `WidgetCenter.reloadAllTimelines()` on every change.
