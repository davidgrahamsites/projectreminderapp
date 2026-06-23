import Foundation

/// Observable single-source-of-truth for one device. The concrete SwiftData-backed
/// implementation (App Group container) is provided by Agent A in this file's expansion;
/// this protocol + in-memory default keep the package compiling and unit-testable now.
@MainActor
public protocol ReminderStoring: AnyObject {
    var document: ReminderDocument { get }
    var settings: ReminderSettings { get }

    func add(_ project: Project)
    func update(_ project: Project)
    func delete(id: Project.ID)
    func move(from source: IndexSet, to destination: Int)
    /// Advance the rotation (move head to tail). Called when the Watch list is dismissed.
    func advanceRotation()
    func setInterval(_ interval: ReminderInterval)
    /// Merge an inbound peer envelope via last-writer-wins.
    func apply(_ envelope: SyncEnvelope)
}

/// In-memory reference implementation. Agent A adds `SwiftDataReminderStore` alongside this
/// for on-device persistence in the App Group container; UI binds to `ReminderStoring`.
@MainActor
public final class InMemoryReminderStore: ReminderStoring {
    public private(set) var document: ReminderDocument
    public private(set) var settings: ReminderSettings

    public init(document: ReminderDocument = .init(), settings: ReminderSettings = .init()) {
        self.document = document
        self.settings = settings
    }

    private func touch() {
        document.version += 1
        document.lastModified = Date()
    }

    public func add(_ project: Project) { document.projects.append(project); touch() }

    public func update(_ project: Project) {
        guard let i = document.projects.firstIndex(where: { $0.id == project.id }) else { return }
        var p = project; p.lastModified = Date()
        document.projects[i] = p; touch()
    }

    public func delete(id: Project.ID) {
        document.projects.removeAll { $0.id == id }; touch()
    }

    public func move(from source: IndexSet, to destination: Int) {
        // Foundation has no Array.move(fromOffsets:) — that's a SwiftUI extension, and
        // ReminderKit stays UI-free. Reorder explicitly with the same semantics.
        let moving = source.sorted().map { document.projects[$0] }
        for index in source.sorted(by: >) { document.projects.remove(at: index) }
        let insertAt = destination - source.filter { $0 < destination }.count
        document.projects.insert(contentsOf: moving, at: max(0, min(insertAt, document.projects.count)))
        touch()
    }

    public func advanceRotation() { document = RotationEngine.advance(document) }

    public func setInterval(_ interval: ReminderInterval) { settings.interval = interval }

    public func apply(_ envelope: SyncEnvelope) {
        document = ReminderDocument.merged(document, envelope.document)
        // Newest settings win on the same LWW basis as the document.
        if envelope.document.version >= document.version { settings = envelope.settings }
    }
}
