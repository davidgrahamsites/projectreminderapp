import Foundation
import ReminderKit

/// @Observable store used by the watch UI until Agent A delivers SwiftDataReminderStore.
/// Mirrors InMemoryReminderStore logic with @Observable so SwiftUI views re-render on change.
/// Switch: replace `WatchStore()` with `SwiftDataReminderStore(...)` at the init site in
/// ProjectReminderWatchApp once A's HANDOFF announces it's ready.
@Observable
@MainActor
final class WatchStore: ReminderStoring {
    private(set) var document: ReminderDocument
    private(set) var settings: ReminderSettings

    init(document: ReminderDocument = .init(), settings: ReminderSettings = .init()) {
        self.document = document
        self.settings = settings
    }

    private func touch() {
        document.version += 1
        document.lastModified = Date()
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

    func advanceRotation() { document = RotationEngine.advance(document) }

    func setInterval(_ interval: ReminderInterval) { settings.interval = interval }

    func apply(_ envelope: SyncEnvelope) {
        document = ReminderDocument.merged(document, envelope.document)
        if envelope.document.version >= document.version { settings = envelope.settings }
    }
}
