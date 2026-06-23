import Foundation

/// A single project the user wants to keep fresh in mind.
/// Value type — the SwiftData persistence model lives in `Store/` and maps to this.
public struct Project: Identifiable, Codable, Equatable, Hashable, Sendable {
    public let id: UUID
    public var title: String
    public var notes: String
    public var createdAt: Date
    public var lastModified: Date

    public init(
        id: UUID = UUID(),
        title: String,
        notes: String = "",
        createdAt: Date = Date(),
        lastModified: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.createdAt = createdAt
        self.lastModified = lastModified
    }
}
