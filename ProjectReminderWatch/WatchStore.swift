import Foundation
import ReminderKit

/// @Observable store for the watch UI. Persists locally (offline) via `LocalPersistence` so the
/// projects survive relaunches, and stays in sync with the iPhone/Mac via WatchConnectivity.
@Observable
@MainActor
final class WatchStore: ReminderStoring {
    private(set) var document: ReminderDocument
    private(set) var settings: ReminderSettings

    init(document: ReminderDocument = .init(), settings: ReminderSettings = .init()) {
        if let saved = LocalPersistence.load() {
            self.document = saved.document
            self.settings = saved.settings
        } else {
            self.document = document
            self.settings = settings
        }
    }

    private func touch() {
        document.version += 1
        document.lastModified = Date()
        persist()
    }

    func add(_ project: Project) { document.projects.append(project); touch() }

    func update(_ project: Project) {
        guard let i = document.projects.firstIndex(where: { $0.id == project.id }) else { return }
        var p = project; p.lastModified = Date()
        document.projects[i] = p; touch()
    }

    func delete(id: Project.ID) {
        document.projects.removeAll { $0.id == id }; touch()
    }

    func move(from source: IndexSet, to destination: Int) {
        let moving = source.sorted().map { document.projects[$0] }
        for index in source.sorted(by: >) { document.projects.remove(at: index) }
        let insertAt = destination - source.filter { $0 < destination }.count
        document.projects.insert(
            contentsOf: moving,
            at: max(0, min(insertAt, document.projects.count))
        )
        touch()
    }

    func advanceRotation() { document = RotationEngine.advance(document); persist() }

    func setInterval(_ interval: ReminderInterval) { settings.interval = interval; persist() }

    func apply(_ envelope: SyncEnvelope) {
        document = ReminderDocument.merged(document, envelope.document)
        if envelope.document.version >= document.version { settings = envelope.settings }
        persist()
    }

    private func persist() {
        LocalPersistence.save(document: document, settings: settings)
    }
}
