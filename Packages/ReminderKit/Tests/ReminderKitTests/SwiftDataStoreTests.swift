import XCTest
import SwiftData
@testable import ReminderKit

/// Tests for `SwiftDataReminderStore` using an in-memory container (no disk, no entitlements).
/// The store conforms to the `@MainActor` `ReminderStoring` protocol, so its `document`/`settings`
/// are main-actor isolated; the test case runs on the main actor to read them synchronously.
@MainActor
final class SwiftDataStoreTests: XCTestCase {

    // MARK: — Helpers

    private func makeStore() -> SwiftDataReminderStore {
        SwiftDataReminderStore(container: SwiftDataReminderStore.makeTestContainer())
    }

    // MARK: — Round-trip

    func testRoundTripProjectAndInterval() {
        let container = SwiftDataReminderStore.makeTestContainer()
        let store = SwiftDataReminderStore(container: container)

        store.add(Project(title: "Alpha"))
        store.setInterval(.hours(2))

        // Same in-memory container — reopening should read back persisted data.
        let store2 = SwiftDataReminderStore(container: container)
        XCTAssertEqual(store2.document.projects.count, 1)
        XCTAssertEqual(store2.document.projects[0].title, "Alpha")
        XCTAssertEqual(store2.settings.interval, .hours(2))
    }

    func testEmptyStoreStartsWithDefaults() {
        let store = makeStore()
        XCTAssertTrue(store.document.projects.isEmpty)
        XCTAssertEqual(store.settings.interval, ReminderSettings().interval)
    }

    // MARK: — CRUD

    func testAddIncreasesCount() {
        let store = makeStore()
        store.add(Project(title: "A"))
        store.add(Project(title: "B"))
        XCTAssertEqual(store.document.projects.count, 2)
        XCTAssertGreaterThan(store.document.version, 0)
    }

    func testUpdateChangesTitle() {
        let store = makeStore()
        store.add(Project(title: "Old"))
        var p = store.document.projects[0]
        p.title = "New"
        store.update(p)
        XCTAssertEqual(store.document.projects[0].title, "New")
    }

    func testDeleteRemovesProject() {
        let store = makeStore()
        store.add(Project(title: "A"))
        store.add(Project(title: "B"))
        let idToDelete = store.document.projects[0].id
        store.delete(id: idToDelete)
        XCTAssertEqual(store.document.projects.count, 1)
        XCTAssertEqual(store.document.projects[0].title, "B")
    }

    func testMoveReordersProjects() {
        let store = makeStore()
        store.add(Project(title: "A"))
        store.add(Project(title: "B"))
        store.add(Project(title: "C"))
        store.move(from: IndexSet(integer: 0), to: 3) // move A to end
        XCTAssertEqual(store.document.projects.map(\.title), ["B", "C", "A"])
    }

    // MARK: — Rotation

    func testAdvanceRotationMovesHead() {
        let store = makeStore()
        store.add(Project(title: "A"))
        store.add(Project(title: "B"))
        store.add(Project(title: "C"))
        store.advanceRotation()
        XCTAssertEqual(store.document.projects.map(\.title), ["B", "C", "A"])
    }

    // MARK: — LWW apply

    func testApplyPicksHigherVersion() {
        let store = makeStore()
        store.add(Project(title: "Local"))

        let remoteDoc = ReminderDocument(
            projects: [Project(title: "Remote")],
            version: 999,
            lastModified: Date()
        )
        let envelope = SyncEnvelope(
            document: remoteDoc,
            settings: ReminderSettings(interval: .minutes(15)),
            deviceID: "peer-1"
        )
        store.apply(envelope)

        XCTAssertEqual(store.document.projects.first?.title, "Remote")
        XCTAssertEqual(store.document.version, 999)
        XCTAssertEqual(store.settings.interval, .minutes(15))
    }

    func testApplyLocalWinsWhenVersionHigher() {
        let store = makeStore()
        store.add(Project(title: "Local"))
        store.add(Project(title: "Local2"))  // version bumped to 2

        let remoteDoc = ReminderDocument(
            projects: [Project(title: "Remote")],
            version: 1,
            lastModified: Date()
        )
        let envelope = SyncEnvelope(document: remoteDoc, settings: .init(), deviceID: "peer-2")
        store.apply(envelope)

        XCTAssertEqual(store.document.projects.count, 2)   // local wins
        XCTAssertEqual(store.document.projects[0].title, "Local")
    }
}
