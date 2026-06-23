import Foundation

/// A tiny App-Group snapshot of the current rotation **head** title, so the watch complication
/// can show it without opening the SwiftData store (avoids actor/Widget lifecycle issues).
/// The watch app writes it whenever the head changes; the complication reads it.
public enum SharedHeadState {
    public static let suiteName = "group.com.danielwang.projectreminder"
    private static let key = "headProjectTitle"

    public static func write(_ title: String?) {
        UserDefaults(suiteName: suiteName)?.set(title, forKey: key)
    }

    public static func read() -> String? {
        UserDefaults(suiteName: suiteName)?.string(forKey: key)
    }
}
