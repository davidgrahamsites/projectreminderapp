import SwiftUI
import WidgetKit
import ReminderKit

@main
struct ProjectReminderWatchApp: App {
    @Environment(\.scenePhase) private var scenePhase

    // WatchStore: @Observable shim until Agent A delivers SwiftDataReminderStore.
    // Switch point: replace `WatchStore()` below with the SwiftData store once
    // A's HANDOFF announces it's available.
    @State private var store = WatchStore()
    @State private var scheduler = HapticScheduler()
    @State private var receiver = WatchConnectivityReceiver()

    var body: some Scene {
        WindowGroup {
            RotatingListView(store: store, scheduler: scheduler)
                .task {
                    // Request permission and arm the first notification.
                    await scheduler.requestAuthorization()
                    scheduler.schedule(interval: store.settings.interval)
                    // Bind WCSession to receive envelopes from the iPhone.
                    receiver.bind(to: store)
                    receiver.activate()
                    publishHead()
                }
                // Keep the complication's head snapshot in sync with any change
                // (rotation advance, inbound sync, edits).
                .onChange(of: store.document) { _, _ in publishHead() }
        }
        // ROTATION LIFECYCLE HOOK — scenePhase → .background
        //
        // Fires when the user presses the Digital Crown or swipes up to close
        // the watch face. This is the "list dismissed" moment per the schema.
        //
        // Why NOT onDisappear on RotatingListView:
        //   Navigating to SettingsView pops the list off the navigation stack,
        //   which fires onDisappear — that would advance the rotation every time
        //   the user opens settings, which is wrong.
        //
        // Why scenePhase and not a notification:
        //   The scene goes .background exactly when the watch display turns off
        //   or the user leaves the app, regardless of how they leave (crown,
        //   swipe, wrist-down). That matches "dismissed/closed" in the spec.
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .background else { return }
            store.advanceRotation()
            // Reschedule so the trigger uses the current interval (in case it
            // was changed in Settings during this session).
            scheduler.schedule(interval: store.settings.interval)
            publishHead()
        }
    }

    /// Mirror the current rotation head into the App-Group snapshot and refresh the
    /// watch-face complication.
    private func publishHead() {
        SharedHeadState.write(store.document.head?.title)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
