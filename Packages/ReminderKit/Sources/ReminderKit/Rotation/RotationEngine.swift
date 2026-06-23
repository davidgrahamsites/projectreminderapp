import Foundation

/// The heart of the app: a deterministic round-robin over the project list.
///
/// Mechanic (from the spec): the list shows the **head** project on top. When the Watch view
/// is dismissed/closed, the shown head moves to the **bottom**, promoting the next project.
///
///   [A, B, C, D]  → show A → dismiss → [B, C, D, A]
///   [B, C, D, A]  → show B → dismiss → [C, D, A, B]
///
/// Pure value transforms so Mac, iPhone, and Watch all agree on order from the same document.
public enum RotationEngine {

    /// The project currently shown on top.
    public static func head(of document: ReminderDocument) -> Project? {
        document.projects.first
    }

    /// Advance the rotation: move the current head to the tail. Call this when the Watch list
    /// is dismissed. Bumps `version`/`lastModified` so the change propagates via sync.
    public static func advance(_ document: ReminderDocument, now: Date = Date()) -> ReminderDocument {
        guard document.projects.count > 1 else {
            // 0 or 1 project: nothing to rotate, but still a no-op-safe return.
            return document
        }
        var doc = document
        let first = doc.projects.removeFirst()
        doc.projects.append(first)
        doc.version += 1
        doc.lastModified = now
        return doc
    }
}
