import SwiftUI
import UserNotifications
import ReminderKit

@main
struct ProjectReminderApp: App {

    // AppStore is @Observable — @State holds it for the app lifetime.
    @State private var store = AppStore()

    // WatchConnectivityTransport must live as long as the app (WCSession holds a weak delegate).
    @State private var wcTransport = WatchConnectivityTransport()

    // LANTransport bridges to the Mac over the local network (Bonjour). The iPhone is the bridge:
    // it relays the Mac's projects to the Watch and vice-versa.
    @State private var lanTransport = LANTransport()

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ProjectListView(store: store)
            }
            .task { setupTransports() }
            .task { await requestNotificationPermission() }
        }
    }

    // MARK: Setup

    /// Wire transports to the store. Called once on first task activation.
    private func setupTransports() {
        store.addTransport(wcTransport)
        store.addTransport(lanTransport)
    }

    /// Request notification permission. The Watch fires the actual haptics, but iOS
    /// permission state may gate paired device notification delivery.
    private func requestNotificationPermission() async {
        _ = try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge])
    }
}
