import SwiftUI
import ReminderKit
import DesignKit

/// The main watch surface: all projects in rotation order, head emphasized on top, styled with
/// the shared DesignKit look (elevation dialed down for the small OLED screen).
///
/// Advance-on-dismiss is handled in ProjectReminderWatchApp via scenePhase → .background,
/// NOT here, so navigating to Settings within the scene does not trigger an advance.
struct RotatingListView: View {
    let store: WatchStore
    let scheduler: HapticScheduler

    var body: some View {
        NavigationStack {
            Group {
                if store.document.projects.isEmpty {
                    emptyState
                } else {
                    projectList
                }
            }
            .containerBackground(Theme.background.gradient, for: .navigation)
            .navigationTitle("Projects")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingsView(store: store, scheduler: scheduler)
                    } label: {
                        Image(systemName: "gear").foregroundStyle(Theme.accent)
                    }
                }
            }
        }
    }

    private var projectList: some View {
        List {
            if let head = store.document.head {
                Section {
                    ProjectCard(title: head.title, subtitle: head.notes)
                        .listRowBackground(Color.clear)
                } header: { label("NOW") }
            }
            let rest = store.document.projects.dropFirst()
            if !rest.isEmpty {
                Section {
                    ForEach(rest) { project in
                        ProjectRow(title: project.title, subtitle: project.notes)
                            .listRowBackground(Color.clear)
                    }
                } header: { label("UP NEXT") }
            }
        }
        .scrollContentBackground(.hidden)
    }

    private func label(_ text: String) -> some View {
        Text(text).font(.system(size: 11, weight: .bold)).tracking(1.2).foregroundStyle(Theme.accent)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "tray").font(.title2).foregroundStyle(Theme.accent)
            Text("No projects yet").font(Theme.display(14, .semibold)).foregroundStyle(Theme.textPrimary)
            Text("Add projects on your Mac or iPhone.")
                .font(.caption2).foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}
