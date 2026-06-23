import SwiftUI
import ReminderKit
import DesignKit

/// Interval selector. Shows all `ReminderInterval.presets` and writes the chosen
/// value back to the store (which triggers sync to Watch and Mac).
struct SettingsView: View {
    var store: AppStore

    var body: some View {
        Form {
            Section {
                Picker("Interval", selection: Binding(
                    get: { store.settings.interval },
                    set: { store.setInterval($0) }
                )) {
                    ForEach(ReminderInterval.presets, id: \.self) { interval in
                        Text(interval.label).tag(interval)
                    }
                }
                .pickerStyle(.wheel)
            } header: {
                Text("Reminder Interval")
            } footer: {
                Text("How often the Watch taps your wrist to resurface the next project.")
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background.ignoresSafeArea())
        .tint(Theme.accent)
        .navigationTitle("Settings")
    }
}
