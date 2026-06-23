import Foundation
import UserNotifications
import WatchKit
import ReminderKit

/// Schedules and reschedules the repeating local notification that drives the interval haptic.
///
/// On watchOS, free-running background timers are prohibited. A repeating
/// UNTimeIntervalNotificationTrigger is the only reliable cadence mechanism.
/// Delivering the notification plays a system haptic automatically; when the
/// app is foregrounded during the interval we additionally call
/// WKInterfaceDevice.current().play(.notification) so the user still feels
/// the prompt.
final class HapticScheduler: NSObject {
    private let center = UNUserNotificationCenter.current()
    private let notificationID = "com.danielwang.projectreminder.interval"

    override init() {
        super.init()
        center.delegate = self
    }

    /// Ask for notification permission. Call once at app launch.
    func requestAuthorization() async {
        _ = try? await center.requestAuthorization(options: [.alert, .sound])
    }

    /// Cancel any pending interval notification and schedule a fresh one.
    /// Call on first launch and whenever the interval changes.
    func schedule(interval: ReminderInterval) {
        center.removePendingNotificationRequests(withIdentifiers: [notificationID])

        let content = UNMutableNotificationContent()
        content.title = "Project Reminder"
        content.body = "Tap to see your current project."
        content.sound = .default  // maps to haptic on watchOS

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: interval.seconds,
            repeats: true
        )
        let request = UNNotificationRequest(
            identifier: notificationID,
            content: content,
            trigger: trigger
        )
        center.add(request)
    }
}

extension HapticScheduler: UNUserNotificationCenterDelegate {
    /// Notification arrived while the app is foregrounded — play haptic directly
    /// and suppress the banner (the user is already looking at the list).
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        WKInterfaceDevice.current().play(.notification)
        completionHandler([])
    }
}
