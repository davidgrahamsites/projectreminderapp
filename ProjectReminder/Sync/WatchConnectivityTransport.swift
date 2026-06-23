import Foundation
import WatchConnectivity
import ReminderKit

/// SyncTransport implementation for iPhone↔Watch via WatchConnectivity.
///
/// Publishing strategy:
///   - `updateApplicationContext`: overwrites the latest context on the Watch; best for
///     full-state LWW sync where only the newest snapshot matters.
///   - `transferUserInfo` fallback: reliable delivery queue used when the context call
///     throws (e.g. context is identical to the last one sent).
///
/// Receiving: listens on both `didReceiveApplicationContext` and `didReceiveUserInfo`
/// so updates sent by either path (from the Watch side) are ingested.
///
/// Pattern adapted from KetoMineralTracker/Packages/MineralKit/Sources/MineralKit/Sync/ConnectivitySyncer.swift.
final class WatchConnectivityTransport: NSObject, SyncTransport {

    // serviceType satisfies the SyncTransport protocol; unused for WatchConnectivity.
    static let serviceType: String = "_projreminder._tcp"

    let incoming: AsyncStream<SyncEnvelope>
    private var continuation: AsyncStream<SyncEnvelope>.Continuation?

    override init() {
        var cont: AsyncStream<SyncEnvelope>.Continuation?
        incoming = AsyncStream { cont = $0 }
        super.init()
        continuation = cont

        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func publish(_ envelope: SyncEnvelope) {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        guard session.activationState == .activated else { return }
        guard let data = try? envelope.encoded() else { return }
        let payload: [String: Any] = ["envelope": data]
        do {
            try session.updateApplicationContext(payload)
        } catch {
            // Context may be rejected if identical to last sent; fall back to reliable queue.
            session.transferUserInfo(payload)
        }
    }

    // MARK: Private

    private func ingest(_ dict: [String: Any]) {
        guard let data = dict["envelope"] as? Data,
              let envelope = try? SyncEnvelope.decoded(from: data) else { return }
        continuation?.yield(envelope)
    }
}

// MARK: WCSessionDelegate

extension WatchConnectivityTransport: WCSessionDelegate {

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {}

    func session(_ session: WCSession,
                 didReceiveApplicationContext applicationContext: [String: Any]) {
        ingest(applicationContext)
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        ingest(userInfo)
    }

    // iOS-only WCSessionDelegate requirements.
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) { WCSession.default.activate() }
}
