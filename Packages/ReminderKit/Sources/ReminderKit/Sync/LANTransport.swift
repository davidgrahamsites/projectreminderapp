#if !os(watchOS)
import Foundation
import Network

/// Mac↔iPhone LAN sync over Bonjour TCP.
///
/// Advertises `_projreminder._tcp` via `NWListener` so peers can discover it,
/// and browses for the same service type via `NWBrowser` to connect to peers.
///
/// Threading: all NW callbacks and `connections` mutations run on `queue` (a serial
/// dispatch queue). `publish` dispatches to `queue` before accessing connections.
/// `incoming` continuation yields are thread-safe and can be consumed from any actor.
///
/// The transport is robust to peers joining and leaving: the browser triggers
/// connect/disconnect; connection failures remove the entry from `connections`.
// `@unchecked Sendable`: all mutable state (`connections`, `outboundEndpoints`) is
// accessed exclusively on `queue` (a serial DispatchQueue), so cross-actor sends are safe.
public final class LANTransport: SyncTransport, @unchecked Sendable {
    public static let serviceType = "_projreminder._tcp"

    private let queue = DispatchQueue(label: "com.danielwang.projectreminder.lan", qos: .utility)

    private var listener: NWListener?
    private var browser: NWBrowser?

    /// All active connections keyed by `ObjectIdentifier(conn)`.
    private var connections: [ObjectIdentifier: NWConnection] = [:]
    /// Endpoints we initiated (outbound). Used to avoid duplicate connections.
    private var outboundEndpoints: Set<NWEndpoint> = []

    private let _continuation: AsyncStream<SyncEnvelope>.Continuation
    public let incoming: AsyncStream<SyncEnvelope>

    public init() {
        (incoming, _continuation) = AsyncStream.makeStream(of: SyncEnvelope.self)
        setupListener()
        setupBrowser()
    }

    deinit {
        listener?.cancel()
        browser?.cancel()
        connections.values.forEach { $0.cancel() }
        _continuation.finish()
    }

    // MARK: — SyncTransport

    /// Fire-and-forget: encodes the envelope and sends it to all currently connected peers.
    /// Never blocks the caller (dispatches to the NW queue).
    public func publish(_ envelope: SyncEnvelope) {
        guard let data = try? envelope.encoded() else { return }
        let frame = Self.frame(data)
        queue.async { [weak self] in
            self?.connections.values.forEach { $0.send(content: frame, completion: .idempotent) }
        }
    }

    // MARK: — Listener (server side)

    private func setupListener() {
        guard let l = try? NWListener(using: .tcp) else { return }
        l.service = NWListener.Service(type: Self.serviceType)
        l.newConnectionHandler = { [weak self] conn in self?.accept(conn) }
        l.stateUpdateHandler = { _ in }   // no-op; could log in debug builds
        l.start(queue: queue)
        listener = l
    }

    private func accept(_ conn: NWConnection) {
        let key = ObjectIdentifier(conn)
        connections[key] = conn
        conn.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                self?.receive(from: conn, key: key)
            case .cancelled, .failed:
                self?.connections.removeValue(forKey: key)
            default:
                break
            }
        }
        conn.start(queue: queue)
    }

    // MARK: — Browser (client side)

    private func setupBrowser() {
        let b = NWBrowser(for: .bonjour(type: Self.serviceType, domain: nil), using: .tcp)
        b.browseResultsChangedHandler = { [weak self] results, _ in
            self?.handleBrowseResults(results)
        }
        b.start(queue: queue)
        browser = b
    }

    private func handleBrowseResults(_ results: Set<NWBrowser.Result>) {
        let found = Set(results.map(\.endpoint))

        // connect to newly discovered peers
        for ep in found where !outboundEndpoints.contains(ep) {
            outboundEndpoints.insert(ep)
            connect(to: ep)
        }

        // cancel connections to peers that disappeared
        let gone = outboundEndpoints.subtracting(found)
        for ep in gone {
            outboundEndpoints.remove(ep)
            for (key, conn) in connections where conn.endpoint == ep {
                conn.cancel()
                connections.removeValue(forKey: key)
            }
        }
    }

    private func connect(to endpoint: NWEndpoint) {
        let conn = NWConnection(to: endpoint, using: .tcp)
        let key = ObjectIdentifier(conn)
        connections[key] = conn
        conn.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                self?.receive(from: conn, key: key)
            case .cancelled, .failed:
                self?.connections.removeValue(forKey: key)
            default:
                break
            }
        }
        conn.start(queue: queue)
    }

    // MARK: — Framing (4-byte big-endian length prefix)

    /// Wraps `data` in a 4-byte length-prefixed frame.
    private static func frame(_ data: Data) -> Data {
        var length = UInt32(data.count).bigEndian
        var out = Data(bytes: &length, count: 4)
        out.append(data)
        return out
    }

    /// Reads one length-prefixed message from `conn` then loops.
    private func receive(from conn: NWConnection, key: ObjectIdentifier) {
        // Phase 1: read the 4-byte length header
        conn.receive(minimumIncompleteLength: 4, maximumLength: 4) { [weak self] data, _, _, error in
            guard let self, error == nil, let data, data.count == 4 else { return }
            let length = Int(UInt32(bigEndian: data.withUnsafeBytes { $0.load(as: UInt32.self) }))
            guard length > 0, length < 1_048_576 else { return }   // sanity cap: 1 MiB

            // Phase 2: read exactly `length` bytes of payload
            conn.receive(minimumIncompleteLength: length, maximumLength: length) { [weak self] body, _, _, err in
                guard let self, err == nil, let body, body.count == length else { return }
                if let envelope = try? SyncEnvelope.decoded(from: body) {
                    self._continuation.yield(envelope)
                }
                self.receive(from: conn, key: key)   // keep reading
            }
        }
    }
}
#endif
