import SwiftUI
import ReminderKit
import DesignKit

/// On-watch interval selector. Tapping a preset calls store.setInterval(_:) and
/// reschedules the UNUserNotificationCenter trigger immediately.
struct SettingsView: View {
    let store: WatchStore
    let scheduler: HapticScheduler

    var body: some View {
        List {
            Section("Reminder Interval") {
                ForEach(ReminderInterval.presets, id: \.self) { preset in
                    Button {
                        store.setInterval(preset)
                        scheduler.schedule(interval: preset)
                    } label: {
                        HStack {
                            Text(preset.label).foregroundStyle(Theme.textPrimary)
                            Spacer()
                            if store.settings.interval == preset {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.accent)
                            }
                        }
                    }
                }
            }
        }
        .containerBackground(Theme.background.gradient, for: .navigation)
        .navigationTitle("Settings")
    }
}
