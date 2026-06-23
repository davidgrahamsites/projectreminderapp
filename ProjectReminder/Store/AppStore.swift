import Foundation
import Observation
import ReminderKit

/// Observable store for the iOS target. Owns document state and transport wiring.
///
/// UI binds to this as `ReminderStoring`; the concrete type is only needed at the root
/// because `@Observable` observation requires the concrete type.
///
/// Transport wiring (the iPhone is the bridge):
///   - User mutations call `publish()` → sends the current `SyncEnvelope` to all transports.
///   - Inbound envelopes from transport A are merged (LWW) and relayed to all other transports.
///   - When Agent A delivers `SwiftDataReminderStore`, replace `document`/`settings` storage
///     with SwiftData persistence; the transport wiring below stays unchanged.
@Observable @MainActor
final class AppStore: ReminderStoring {

    private(set) var document: ReminderDocument
    private(set) var settings: ReminderSettings

    // MARK: Transport wiring (not observed by SwiftUI — ignore in tracking)

    @ObservationIgnored
    private var transports: [any SyncTransport] = []
    @ObservationIgnored
    private var inboundTasks: [Task<Void, Never>] = []
    @ObservationIgnored
    private let deviceID: String = AppStore.stableDeviceID()

    // MARK: Init

    init(document: ReminderDocument = .init(), settings: ReminderSettings = .init()) {
        // Load previously persisted projects so they survive relaunches offline.
        if let saved = LocalPersistence.load() {
            self.document = saved.document
            self.settings = saved.settings
        } else {
            self.document = document
            self.settings = settings
        }
    }

    deinit {
        inboundTasks.forEach { $0.cancel() }
    }

    // MARK: Transport registration

    /// Register a transport at app startup. Starts consuming its `incoming` stream.
    func addTransport(_ transport: any SyncTransport) {
        transports.append(transport)
        let task = Task { [weak self] in
            guard let self else { return }
            for await envelope in transport.incoming {
                await self.receive(envelope, from: transport)
            }
        }
        inboundTasks.append(task)
    }

    // MARK: ReminderStoring

    func add(_ project: Project) {
        document.projects.append(project)
        touch()
    }

    func update(_ project: Project) {
        guard let i = document.projects.firstIndex(where: { $0.id == project.id }) else { return }
        var p = project; p.lastModified = Date()
        document.projects[i] = p
        touch()
    }

    func delete(id: Project.ID) {
        document.projects.removeAll { $0.id == id }
        touch()
    }

    func move(from source: IndexSet, to destination: Int) {
        // Mirrors InMemoryReminderStore.move — Foundation has no Array.move(fromOffsets:).
        let moving = source.sorted().map { document.projects[$0] }
        for index in source.sorted(by: >) { document.projects.remove(at: index) }
        let insertAt = destination - source.filter { $0 < destination }.count
        document.projects.insert(contentsOf: moving, at: max(0, min(insertAt, document.projects.count)))
        touch()
    }

    func advanceRotation() {
        document = RotationEngine.advance(document)
        persist()
        publish()
    }

    func setInterval(_ interval: ReminderInterval) {
        settings.interval = interval
        persist()
        publish()
    }

    /// Merge inbound peer state (LWW). Does NOT publish outward — `receive` handles relay.
    func apply(_ envelope: SyncEnvelope) {
        document = ReminderDocument.merged(document, envelope.document)
        if envelope.document.version >= document.version {
            settings = envelope.settings
        }
        persist()
    }

    // MARK: Private

    private func touch() {
        document.version += 1
        document.lastModified = Date()
        persist()
        publish()
    }

    /// Save the current state to disk so it survives relaunches offline.
    private func persist() {
        LocalPersistence.save(document: document, settings: settings)
    }

    /// Publishes current state to every registered transport (fire-and-forget).
    private func publish() {
        let envelope = currentEnvelope()
        for t in transports { t.publish(envelope) }
    }

    /// Called when a transport delivers an inbound envelope. Merges into local state and
    /// relays to all other transports so the iPhone bridges Mac↔Watch.
    private func receive(_ envelope: SyncEnvelope, from source: any SyncTransport) {
        let prevVersion = document.version
        apply(envelope)
        guard document.version != prevVersion else { return }
        // Document was updated — relay to all other transports.
        let updated = currentEnvelope()
        let sourceID = ObjectIdentifier(source)
        for t in transports where ObjectIdentifier(t) != sourceID {
            t.publish(updated)
        }
    }

    private func currentEnvelope() -> SyncEnvelope {
        SyncEnvelope(document: document, settings: settings, deviceID: deviceID, sentAt: Date())
    }

    /// Stable per-install device identifier stored in UserDefaults (avoids UIKit import).
    private static func stableDeviceID() -> String {
        let key = "com.danielwang.projectreminder.deviceID"
        if let id = UserDefaults.standard.string(forKey: key) { return id }
        let id = UUID().uuidString
        UserDefaults.standard.set(id, forKey: key)
        return id
    }
}
