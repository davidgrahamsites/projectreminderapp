import XCTest
@testable import ReminderKit

final class RotationEngineTests: XCTestCase {

    private func doc(_ titles: [String]) -> ReminderDocument {
        ReminderDocument(projects: titles.map { Project(title: $0) })
    }
    private func titles(_ d: ReminderDocument) -> [String] { d.projects.map(\.title) }

    func testHeadIsFirstProject() {
        XCTAssertEqual(RotationEngine.head(of: doc(["A", "B", "C"]))?.title, "A")
        XCTAssertNil(RotationEngine.head(of: doc([])))
    }

    func testAdvanceMovesHeadToBottom() {
        let d1 = RotationEngine.advance(doc(["A", "B", "C", "D"]))
        XCTAssertEqual(titles(d1), ["B", "C", "D", "A"])
        let d2 = RotationEngine.advance(d1)
        XCTAssertEqual(titles(d2), ["C", "D", "A", "B"])
    }

    func testAdvanceFullCycleReturnsToStart() {
        var d = doc(["A", "B", "C"])
        for _ in 0..<3 { d = RotationEngine.advance(d) }
        XCTAssertEqual(titles(d), ["A", "B", "C"])
    }

    func testAdvanceBumpsVersionAndTimestamp() {
        let before = doc(["A", "B"])
        let after = RotationEngine.advance(before, now: before.lastModified.addingTimeInterval(10))
        XCTAssertEqual(after.version, before.version + 1)
        XCTAssertGreaterThan(after.lastModified, before.lastModified)
    }

    func testAdvanceIsNoOpForZeroOrOne() {
        XCTAssertEqual(titles(RotationEngine.advance(doc([]))), [])
        XCTAssertEqual(titles(RotationEngine.advance(doc(["A"]))), ["A"])
        // No version bump when nothing rotates.
        XCTAssertEqual(RotationEngine.advance(doc(["A"])).version, 0)
    }

    func testMergePicksHigherVersion() {
        var a = doc(["A"]); a.version = 5
        var b = doc(["B"]); b.version = 9
        XCTAssertEqual(ReminderDocument.merged(a, b).projects.first?.title, "B")
    }
}
