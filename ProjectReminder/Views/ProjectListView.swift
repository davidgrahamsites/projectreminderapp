import SwiftUI
import ReminderKit
import DesignKit

/// Root list view: all projects in rotation order (index 0 = current head), styled with the
/// shared neumorphic-purple DesignKit look. Supports add, delete, reorder, and tap-to-edit.
struct ProjectListView: View {
    var store: AppStore

    @State private var isPresentingAdd = false
    @State private var editingProject: Project?

    private var projects: [Project] { store.document.projects }

    var body: some View {
        Group {
            if projects.isEmpty {
                ContentUnavailableView(
                    "No projects yet",
                    systemImage: "tray",
                    description: Text("Tap + to add a project, or add them on your Mac.")
                )
            } else {
                List {
                    if let head = projects.first {
                        Section {
                            ProjectCard(title: head.title, subtitle: head.notes)
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .onTapGesture { editingProject = head }
                        } header: { sectionLabel("NOW") }
                    }
                    let rest = Array(projects.dropFirst())
                    if !rest.isEmpty {
                        Section {
                            ForEach(rest) { project in
                                ProjectRow(title: project.title, subtitle: project.notes)
                                    .listRowBackground(Color.clear)
                                    .onTapGesture { editingProject = project }
                            }
                            .onDelete(perform: deleteRest)
                            .onMove { store.move(from: shift($0), to: $1 + 1) }
                        } header: { sectionLabel("UP NEXT") }
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
        .screenBackground()
        .navigationTitle("Projects")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                NavigationLink { SettingsView(store: store) } label: { Image(systemName: "gear") }
            }
            ToolbarItem(placement: .topBarTrailing) { EditButton() }
            ToolbarItem(placement: .topBarTrailing) {
                Button { isPresentingAdd = true } label: { Image(systemName: "plus") }
            }
        }
        .tint(Theme.accent)
        .sheet(isPresented: $isPresentingAdd) { ProjectEditView(store: store, project: nil) }
        .sheet(item: $editingProject) { ProjectEditView(store: store, project: $0) }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text).font(.system(size: 12, weight: .bold)).tracking(1.4).foregroundStyle(Theme.accent)
    }

    /// "Up Next" is `projects.dropFirst()`, so its index 0 maps to store index 1.
    private func shift(_ offsets: IndexSet) -> IndexSet { IndexSet(offsets.map { $0 + 1 }) }

    private func deleteRest(_ offsets: IndexSet) {
        let rest = Array(projects.dropFirst())
        offsets.map { rest[$0].id }.forEach { store.delete(id: $0) }
    }
}
