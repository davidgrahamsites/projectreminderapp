import SwiftUI
import ReminderKit

/// Sheet for adding a new project (project == nil) or editing an existing one.
struct ProjectEditView: View {
    var store: AppStore
    var project: Project?

    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var notes: String = ""

    private var isAdding: Bool { project == nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Title") {
                    TextField("Project name", text: $title)
                        .autocorrectionDisabled()
                }
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }
            }
            .navigationTitle(isAdding ? "New Project" : "Edit Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .onAppear {
            title = project?.title ?? ""
            notes = project?.notes ?? ""
        }
    }

    private func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        guard !trimmedTitle.isEmpty else { return }
        if let existing = project {
            var updated = existing
            updated.title = trimmedTitle
            updated.notes = notes
            store.update(updated)
        } else {
            store.add(Project(title: trimmedTitle, notes: notes))
        }
        dismiss()
    }
}
