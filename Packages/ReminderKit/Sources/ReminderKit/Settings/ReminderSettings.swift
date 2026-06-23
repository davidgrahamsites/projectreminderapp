import Foundation

/// User-tunable settings, shown by the interval selector on all three platforms.
public struct ReminderSettings: Codable, Equatable, Sendable {
    /// How often the Watch fires a haptic and surfaces the next project.
    public var interval: ReminderInterval

    public init(interval: ReminderInterval = .minutes(60)) {
        self.interval = interval
    }
}

/// A reminder cadence. Backed by seconds so it serializes cleanly and feeds
/// `UNTimeIntervalNotificationTrigger` directly on watchOS.
public enum ReminderInterval: Codable, Equatable, Hashable, Sendable {
    case minutes(Int)
    case hours(Int)

    /// Cadence in seconds. Apple's repeating local-notification trigger requires >= 60s.
    public var seconds: TimeInterval {
        switch self {
        case .minutes(let m): return TimeInterval(max(1, m) * 60)
        case .hours(let h): return TimeInterval(max(1, h) * 3600)
        }
    }

    /// Preset choices offered by the interval picker UI.
    public static let presets: [ReminderInterval] = [
        .minutes(15), .minutes(30), .minutes(60), .hours(2), .hours(4)
    ]

    public var label: String {
        switch self {
        case .minutes(let m): return "\(m) min"
        case .hours(let h): return h == 1 ? "1 hour" : "\(h) hours"
        }
    }
}
