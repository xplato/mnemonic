import SwiftUI

struct DirectoryRowView: View {
    let directory: MnemonicDirectory
    @Environment(DirectoryStore.self) private var store
    @State private var showDeleteConfirmation = false

    var body: some View {
        HStack {
            Image(systemName: "folder.fill")
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(directory.label ?? directory.path)
                    .font(.body)
                Text(directory.path)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()

            Toggle("Watch", isOn: Binding(
                get: { directory.watch },
                set: { newValue in
                    guard let id = directory.id else { return }
                    try? store.database.updateDirectoryWatch(id: id, watch: newValue)
                }
            ))
            .toggleStyle(.switch)
            .labelsHidden()

            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
            .confirmationDialog(
                "Remove \"\(directory.label ?? directory.path)\"?",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Remove", role: .destructive) {
                    guard let id = directory.id else { return }
                    try? store.database.deleteDirectory(id: id)
                }
            } message: {
                Text("This will remove the directory from indexing. Files on disk will not be affected.")
            }
        }
        .padding(.vertical, 4)
    }
}
