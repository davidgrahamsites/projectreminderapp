import XCTest
@testable import ReminderKit

/// Tests for `SyncEnvelope` encode/decode and for the LWW merge logic at the
/// document level (the cross-transport contract).
final class SyncEnvelopeTests: XCTestCase {

    // MARK: — Encode / decode

    func testEnvelopeRoundTrip() throws {
        let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)
        let doc = ReminderDocument(
            projects: [Project(id: UUID(), title: "Alpha", notes: "n1",
                               createdAt: fixedDate, lastModified: fixedDate)],
            version: 7,
            lastModified: fixedDate
        )
        let settings = ReminderSettings(interval: .hours(4))
        let original = SyncEnvelope(document: doc, settings: settings,
                                    deviceID: "dev-ABC", sentAt: fixedDate)

        let data = try original.encoded()
        let decoded = try SyncEnvelope.decoded(from: data)

        XCTAssertEqual(decoded, original)
    }

    func testEnvelopePreservesProjectOrder() throws {
        let projects = ["A", "B", "C", "D"].map { Project(title: $0) }
        let doc = ReminderDocument(projects: projects, version: 1)
        let env = SyncEnvelope(document: doc, settings: .init(), deviceID: "x",
                               sentAt: Date(timeIntervalSince1970: 0))

        let decoded = try SyncEnvelope.decoded(from: try env.encoded())
        XCTAssertEqual(decoded.document.projects.map(\.title), ["A", "B", "C", "D"])
    }

    func testEnvelopeWithEmptyProjectList() throws {
        let env = SyncEnvelope(document: .init(), settings: .init(), deviceID: "empty",
                               sentAt: Date(timeIntervalSince1970: 0))
        let decoded = try SyncEnvelope.decoded(from: try env.encoded())
        XCTAssertTrue(decoded.document.projects.isEmpty)
    }

    // MARK: — LWW merge (ReminderDocument.merged)

    func testMergedPicksHigherVersion() {
        let a = ReminderDocument(projects: [Project(title: "A")], version: 3)
        let b = ReminderDocument(projects: [Project(title: "B")], version: 10)
        XCTAssertEqual(ReminderDocument.merged(a, b).projects.first?.title, "B")
        XCTAssertEqual(ReminderDocument.merged(b, a).projects.first?.title, "B")
    }

    func testMergedTieBreaksByLastModified() {
        let earlier = Date(timeIntervalSince1970: 1000)
        let later   = Date(timeIntervalSince1970: 2000)
        let a = ReminderDocument(projects: [Project(title: "Old")], version: 5, lastModified: earlier)
        let b = ReminderDocument(projects: [Project(title: "New")], version: 5, lastModified: later)
        XCTAssertEqual(ReminderDocument.merged(a, b).projects.first?.title, "New")
    }

    func testMergedSameVersionSameDate_picksA() {
        // When perfectly tied, merged(a, b) returns a (a.lastModified >= b.lastModified).
        let date = Date(timeIntervalSince1970: 500)
        let a = ReminderDocument(projects: [Project(title: "A")], version: 2, lastModified: date)
        let b = ReminderDocument(projects: [Project(title: "B")], version: 2, lastModified: date)
        XCTAssertEqual(ReminderDocument.merged(a, b).projects.first?.title, "A")
    }

    // MARK: — ReminderInterval encoding

    func testIntervalPresetsRoundTrip() throws {
        for preset in ReminderInterval.presets {
            let settings = ReminderSettings(interval: preset)
            let data = try JSONEncoder().encode(settings)
            let decoded = try JSONDecoder().decode(ReminderSettings.self, from: data)
            XCTAssertEqual(decoded.interval, preset,
                           "Preset \(preset.label) did not survive encode/decode")
        }
    }
}
