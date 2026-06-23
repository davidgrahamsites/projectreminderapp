import Foundation

/// The full synced state of the app: the ordered list of projects plus rotation position.
///
/// This is the single value that travels across every transport (WatchConnectivity, LAN,
/// and — later — CloudKit). It is the unit of last-writer-wins conflict resolution: the
/// document with the higher `version` (ties broken by `lastModified`) wins.
public struct ReminderDocument: Codable, Equatable, Sendable {
    /// Ordered list. `projects[0]` is the rotation **head** — the project shown on top.
    public var projects: [Project]
    /// Monotonic version counter, bumped on every mutation. Drives LWW merge.
    public var version: Int
    /// Wall-clock of the last mutation. Tie-breaker for LWW.
    public var lastModified: Date

    public init(projects: [Project] = [], version: Int = 0, lastModified: Date = Date()) {
        self.projects = projects
        self.version = version
        self.lastModified = lastModified
    }

    /// The project currently shown on top of the Watch list, if any.
    public var head: Project? { projects.first }

    /// Last-writer-wins: returns whichever document is newer (higher version, then later date).
    public static func merged(_ a: ReminderDocument, _ b: ReminderDocument) -> ReminderDocument {
        if a.version != b.version { return a.version > b.version ? a : b }
        return a.lastModified >= b.lastModified ? a : b
    }
}
