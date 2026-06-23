import Foundation
import WatchConnectivity
import ReminderKit

/// Receives SyncEnvelopes from the iPhone companion app via WCSession.
///
/// WCSession message contract (coordinated with Agent B HANDOFF 2026-06-23):
///   - Key: "envelope"
///   - Value: Data (JSON-encoded SyncEnvelope via SyncEnvelope.encoded())
///   - Primary channel: updateApplicationContext → didReceiveApplicationContext
///   - Fallback channel: transferUserInfo → didReceiveUserInfo
final class WatchConnectivityReceiver: NSObject {
    // Weak to avoid a retain cycle; the App struct's @State owns the store.
    private weak var store: WatchStore?

    func bind(to store: WatchStore) {
        self.store = store
    }

    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }
}

extension WatchConnectivityReceiver: WCSessionDelegate {
    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        // No action needed on activation.
    }

    /// Primary path: applicationContext (passive, battery-efficient background sync).
    func session(
        _ session: WCSession,
        didReceiveApplicationContext applicationContext: [String: Any]
    ) {
        applyIfPresent(applicationContext)
    }

    /// Fallback path: transferUserInfo (used when updateApplicationContext throws on iPhone).
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        applyIfPresent(userInfo)
    }

    // MARK: - Private

    private func applyIfPresent(_ dict: [String: Any]) {
        guard let data = dict["envelope"] as? Data,
              let envelope = try? SyncEnvelope.decoded(from: data) else { return }
        // SyncEnvelope is Sendable; hop to main actor for store mutation.
        Task { @MainActor [weak self] in
            self?.store?.apply(envelope)
        }
    }
}
