import SwiftUI
import ReminderKit
import DesignKit

/// Main window: the project list (rotation order), add/edit/delete/reorder, interval setting,
/// and LAN sync status. Styled with the shared neumorphic-purple DesignKit look.
struct MacContentView: View {
    @Bindable var bridge: MacBridge
    @State private var editing: Project?
    @State private var isAdding = false

    private var projects: [Project] { bridge.store.document.projects }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().opacity(0.4)
            content
            footer
        }
        .screenBackground()
        .sheet(isPresented: $isAdding) {
            ProjectEditor(title: "", notes: "") { bridge.add(Project(title: $0, notes: $1)) }
        }
        .sheet(item: $editing) { p in
            ProjectEditor(title: p.title, notes: p.notes) {
                var updated = p; updated.title = $0; updated.notes = $1
                bridge.update(updated)
            }
        }
    }

    // MARK: Header (title + interval + add)

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Project Reminder")
                    .font(Theme.display(24, .bold))
                    .foregroundStyle(Theme.textPrimary)
                Text("Keep what you're building top of mind.")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            intervalMenu
            Button { isAdding = true } label: { Label("Add project", systemImage: "plus") }
                .buttonStyle(.accent)
        }
        .padding(20)
    }

    private var intervalMenu: some View {
        Menu {
            ForEach(ReminderInterval.presets, id: \.self) { preset in
                Button { bridge.setInterval(preset) } label: {
                    HStack {
                        Text(preset.label)
                        if bridge.store.settings.interval == preset { Image(systemName: "checkmark") }
                    }
                }
            }
        } label: {
            Label("Every \(bridge.store.settings.interval.label)", systemImage: "bell.badge")
                .font(Theme.display(13, .medium))
                .foregroundStyle(Theme.accent)
                .padding(.horizontal, 12).padding(.vertical, 8)
                .sunken(cornerRadius: 12)
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }

    // MARK: List

    @ViewBuilder private var content: some View {
        if projects.isEmpty {
            VStack(spacing: 10) {
                Image(systemName: "tray").font(.system(size: 34)).foregroundStyle(Theme.textSecondary)
                Text("No projects yet").font(Theme.display(16, .semibold)).foregroundStyle(Theme.textPrimary)
                Text("Add a project — it'll start resurfacing on your watch.")
                    .font(.system(size: 12)).foregroundStyle(Theme.textSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List {
                if let head = projects.first {
                    Section {
                        ProjectCard(title: head.title, subtitle: head.notes)
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .onTapGesture { editing = head }
                    } header: { sectionLabel("NOW") }
                }
                let rest = Array(projects.dropFirst())
                if !rest.isEmpty {
                    Section {
                        ForEach(rest) { p in
                            ProjectRow(title: p.title, subtitle: p.notes)
                                .listRowBackground(Color.clear)
                                .contentShape(Rectangle())
                                .onTapGesture { editing = p }
                        }
                        .onMove { bridge.move(from: $0, to: $1.advanced(by: 1)) }
                        .onDelete { offsets in
                            offsets.map { rest[$0].id }.forEach { bridge.delete(id: $0) }
                        }
                    } header: { sectionLabel("UP NEXT") }
                }
            }
            .scrollContentBackground(.hidden)
            .listStyle(.inset)
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text).font(.system(size: 11, weight: .bold)).tracking(1.4).foregroundStyle(Theme.accent)
    }

    // MARK: Footer (sync status)

    private var footer: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi").foregroundStyle(Theme.accent)
            Text(bridge.lastSyncNote).font(.system(size: 11)).foregroundStyle(Theme.textSecondary)
            Spacer()
        }
        .padding(.horizontal, 20).padding(.vertical, 12)
    }
}
