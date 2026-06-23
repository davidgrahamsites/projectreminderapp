import Foundation

/// Tiny on-disk persistence for the document + settings, used by the iOS and watch stores so
/// their projects survive app relaunches **offline** (no App Group / iCloud needed — works on a
/// free Apple personal team). The Mac app persists separately via `SwiftDataReminderStore`.
///
/// Stored as a single JSON file in the app's own Documents directory (per-device, sandboxed).
public enum LocalPersistence {
    private struct Snapshot: Codable {
        var document: ReminderDocument
        var settings: ReminderSettings
    }

    private static var fileURL: URL {
        URL.documentsDirectory.appendingPathComponent("ProjectReminder.json")
    }

    public static func load() -> (document: ReminderDocument, settings: ReminderSettings)? {
        guard let data = try? Data(contentsOf: fileURL),
              let snap = try? JSONDecoder().decode(Snapshot.self, from: data) else { return nil }
        return (snap.document, snap.settings)
    }

    public static func save(document: ReminderDocument, settings: ReminderSettings) {
        let snap = Snapshot(document: document, settings: settings)
        guard let data = try? JSONEncoder().encode(snap) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
