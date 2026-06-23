import SwiftUI
import DesignKit

/// Add / edit sheet for a single project. Returns (title, notes) on save.
struct ProjectEditor: View {
    @Environment(\.dismiss) private var dismiss
    @State var title: String
    @State var notes: String
    let onSave: (String, String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title.isEmpty ? "New project" : "Edit project")
                .font(Theme.display(18, .bold))
                .foregroundStyle(Theme.textPrimary)

            TextField("Project title", text: $title)
                .textFieldStyle(.plain)
                .font(Theme.display(15, .medium))
                .padding(12)
                .sunken(cornerRadius: 12)

            TextField("Notes (optional)", text: $notes, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(3...6)
                .padding(12)
                .sunken(cornerRadius: 12)

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Save") {
                    let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    onSave(trimmed, notes.trimmingCharacters(in: .whitespacesAndNewlines))
                    dismiss()
                }
                .buttonStyle(.accent)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 380)
        .screenBackground()
    }
}
