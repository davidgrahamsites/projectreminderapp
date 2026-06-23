import Foundation
import SwiftData

// MARK: — Persistence model

/// Single-record persistence model. Stores the full document and settings as JSON
/// so there is no complex mapping layer. A project list of ~20 entries serialises
/// in microseconds; the simplicity wins here.
@Model final class AppState {
    var documentData: Data
    var settingsData: Data

    init(documentData: Data, settingsData: Data) {
        self.documentData = documentData
        self.settingsData = settingsData
    }
}

// MARK: — Store

/// SwiftData-backed `ReminderStoring` implementation.
///
/// Persist to the shared App Group container (`group.com.danielwang.projectreminder`)
/// so all three platform targets read the same store. Use `makeProductionContainer()`
/// in app code and `makeTestContainer()` in unit tests (no disk, no entitlements).
///
/// `@Observable` so SwiftUI can bind to `document` and `settings` directly.
/// The class methods are `nonisolated` (they can be called from any context); the
/// `@MainActor ReminderStoring` protocol conformance means protocol callers dispatch
/// through the main actor automatically. In practice all mutations originate from
/// SwiftUI actions (main actor), so observation updates always arrive on the main thread.
@Observable public final class SwiftDataReminderStore: ReminderStoring {
    public private(set) var document: ReminderDocument
    public private(set) var settings: ReminderSettings

    // Uses `ModelContext(container)` — NOT the @MainActor-isolated `container.mainContext` —
    // so the initialiser can run synchronously from any calling context (including test code).
    private let context: ModelContext
    private var record: AppState?

    // MARK: Init

    /// Designated initialiser. Loads any persisted state synchronously.
    ///
    /// - Parameter container: A `ModelContainer` configured for `AppState`.
    ///   Inject `makeTestContainer()` in tests, `makeProductionContainer()` in production.
    public init(container: ModelContainer) {
        self.context = ModelContext(container)
        let fetched = (try? context.fetch(FetchDescriptor<AppState>())) ?? []
        if let state = fetched.first {
            document = (try? JSONDecoder().decode(ReminderDocument.self, from: state.documentData)) ?? .init()
            settings = (try? JSONDecoder().decode(ReminderSettings.self, from: state.settingsData)) ?? .init()
            record = state
        } else {
            document = .init()
            settings = .init()
            record = nil
        }
    }

    // MARK: Container factories

    /// Production container stored in the App Group container.
    /// Falls back to the documents directory if the group identifier is unavailable
    /// (e.g. Simulator without the entitlement applied).
    public static func makeProductionContainer() -> ModelContainer {
        let url: URL
        if let groupURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.danielwang.projectreminder"
        ) {
            url = groupURL.appendingPathComponent("AppState.store")
        } else {
            url = URL.documentsDirectory.appendingPathComponent("AppState.store")
        }
        // Using try! is intentional — a corrupted persistent store is a fatal condition here.
        return try! ModelContainer(for: AppState.self, configurations: ModelConfiguration(url: url))
    }

    /// In-memory container for unit tests (no disk I/O, no entitlements required).
    public static func makeTestContainer() -> ModelContainer {
        return try! ModelContainer(
            for: AppState.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    // MARK: ReminderStoring
    //
    // These methods are nonisolated on the concrete class (so tests can call them
    // synchronously), but they satisfy the @MainActor ReminderStoring requirements
    // because a nonisolated witness is legal for a @MainActor protocol requirement.

    public func add(_ project: Project) {
        document.projects.append(project)
        touch()
        save()
    }

    public func update(_ project: Project) {
        guard let i = document.projects.firstIndex(where: { $0.id == project.id }) else { return }
        var p = project; p.lastModified = Date()
        document.projects[i] = p
        touch()
        save()
    }

    public func delete(id: Project.ID) {
        document.projects.removeAll { $0.id == id }
        touch()
        save()
    }

    public func move(from source: IndexSet, to destination: Int) {
        // Foundation has no Array.move(fromOffsets:) — that's a SwiftUI extension.
        // Reorder explicitly with the same semantics as InMemoryReminderStore.
        let moving = source.sorted().map { document.projects[$0] }
        for index in source.sorted(by: >) { document.projects.remove(at: index) }
        let insertAt = destination - source.filter { $0 < destination }.count
        document.projects.insert(contentsOf: moving, at: max(0, min(insertAt, document.projects.count)))
        touch()
        save()
    }

    public func advanceRotation() {
        // RotationEngine.advance already bumps version + lastModified.
        document = RotationEngine.advance(document)
        save()
    }

    public func setInterval(_ interval: ReminderInterval) {
        settings.interval = interval
        save()
    }

    /// Merge an inbound peer envelope via last-writer-wins.
    ///
    /// Settings follow the document: the envelope's settings apply only when
    /// the envelope document "won" (higher or equal version).
    public func apply(_ envelope: SyncEnvelope) {
        document = ReminderDocument.merged(document, envelope.document)
        if envelope.document.version >= document.version {
            settings = envelope.settings
        }
        save()
    }

    // MARK: Private

    private func touch() {
        document.version += 1
        document.lastModified = Date()
    }

    private func save() {
        guard let docData = try? JSONEncoder().encode(document),
              let setData = try? JSONEncoder().encode(settings) else { return }
        if let record {
            record.documentData = docData
            record.settingsData = setData
        } else {
            let r = AppState(documentData: docData, settingsData: setData)
            context.insert(r)
            self.record = r
        }
        try? context.save()
    }
}
