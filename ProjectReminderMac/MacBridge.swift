import Foundation
import Observation
import ReminderKit

/// Wires the macOS authoring UI to persistence (`SwiftDataReminderStore`) and LAN sync
/// (`LANTransport`), and posts fire-and-forget events to the App Opener Hub data bus.
///
/// The Mac is the authoring surface: every edit persists, publishes to LAN peers (iPhone),
/// and pings the Hub. Inbound peer envelopes are merged via the store's LWW `apply`.
@Observable
@MainActor
final class MacBridge {
    let store: SwiftDataReminderStore

    @ObservationIgnored private let transport = LANTransport()
    @ObservationIgnored private let deviceID = "mac-" + (Host.current().localizedName ?? UUID().uuidString)
    @ObservationIgnored private var inbound: Task<Void, Never>?

    /// Last sync activity, surfaced in the UI as host status.
    var lastSyncNote = "Listening for devices on this network…"

    init() {
        store = SwiftDataReminderStore(container: SwiftDataReminderStore.makeProductionContainer())
        inbound = Task { [weak self] in
            guard let self else { return }
            for await envelope in transport.incoming {
                await MainActor.run {
                    self.store.apply(envelope)
                    self.lastSyncNote = "Synced from a device · \(Self.timestamp())"
                }
            }
        }
        // Seed the transport with the current (persisted) projects so any device that connects
        // later immediately receives them — the Mac is the authoring source of truth.
        transport.publish(SyncEnvelope(document: store.document, settings: store.settings, deviceID: deviceID))
    }

    deinit { inbound?.cancel() }

    // MARK: Mutations (persist → publish → Hub)

    func add(_ project: Project) { store.add(project); didChange("Added “\(project.title)”") }
    func update(_ project: Project) { store.update(project); didChange("Edited “\(project.title)”") }
    func delete(id: Project.ID) { store.delete(id: id); didChange("Deleted a project") }
    func move(from s: IndexSet, to d: Int) { store.move(from: s, to: d); didChange("Reordered projects") }
    func setInterval(_ i: ReminderInterval) { store.setInterval(i); didChange("Interval → \(i.label)") }

    private func didChange(_ note: String) {
        let envelope = SyncEnvelope(document: store.document, settings: store.settings, deviceID: deviceID)
        transport.publish(envelope)
        lastSyncNote = "\(note) · published \(Self.timestamp())"
        Hub.post(note)
    }

    private static func timestamp() -> String {
        let f = DateFormatter(); f.timeStyle = .short; return f.string(from: Date())
    }
}

/// Fire-and-forget App Opener Hub data-bus client (Mac only — iOS/watch can't reach localhost).
enum Hub {
    static let appName = "Project Reminder"

    static func post(_ content: String) {
        guard let url = URL(string: "http://127.0.0.1:9800/apps/\(appName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? appName)/send") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 2
        req.httpBody = try? JSONSerialization.data(withJSONObject: [
            "content": content, "role": "assistant", "metadata": [:]
        ])
        // Best-effort: ignore all failures, never block the UI.
        URLSession.shared.dataTask(with: req).resume()
    }
}
