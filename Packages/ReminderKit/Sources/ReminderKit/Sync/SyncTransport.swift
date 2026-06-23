import Foundation

/// The envelope that crosses every transport. Wraps a full document so receivers can
/// merge via last-writer-wins. Carrying `settings` keeps interval changes in sync too.
public struct SyncEnvelope: Codable, Equatable, Sendable {
    public var document: ReminderDocument
    public var settings: ReminderSettings
    public var deviceID: String
    public var sentAt: Date

    public init(document: ReminderDocument, settings: ReminderSettings, deviceID: String, sentAt: Date = Date()) {
        self.document = document
        self.settings = settings
        self.deviceID = deviceID
        self.sentAt = sentAt
    }

    public func encoded() throws -> Data { try JSONEncoder().encode(self) }
    public static func decoded(from data: Data) throws -> SyncEnvelope {
        try JSONDecoder().decode(SyncEnvelope.self, from: data)
    }
}

/// The iCloud-ready seam. Today: `WatchConnectivityTransport` (phone↔watch) and
/// `LANTransport` (Mac↔iPhone, Bonjour). Tomorrow: a `CloudKitTransport` slots in here
/// with zero changes to callers. Implementations live in the app targets / Store layer.
public protocol SyncTransport: AnyObject {
    /// Bonjour service type shared by LAN peers.
    static var serviceType: String { get }
    /// Publish the local state to peers (fire-and-forget; never block the UI).
    func publish(_ envelope: SyncEnvelope)
    /// Stream of envelopes arriving from peers, to be merged with `ReminderDocument.merged`.
    var incoming: AsyncStream<SyncEnvelope> { get }
}

public extension SyncTransport {
    static var serviceType: String { "_projreminder._tcp" }
}
