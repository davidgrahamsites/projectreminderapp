import SwiftUI
import ReminderKit
import DesignKit

/// macOS authoring app — where you set up the projects that resurface on your wrist.
@main
struct ProjectReminderMacApp: App {
    @State private var bridge = MacBridge()

    var body: some Scene {
        WindowGroup {
            MacContentView(bridge: bridge)
                .frame(minWidth: 520, minHeight: 480)
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 620, height: 560)
    }
}
