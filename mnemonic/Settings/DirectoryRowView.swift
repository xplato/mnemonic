import SwiftUI

struct DirectoryRowView: View {
  let directory: MnemonicDirectory
  @Environment(DirectoryStore.self) private var store
  @Environment(CLIPModelManager.self) private var modelManager
  @State private var showDeleteConfirmation = false

  private var indexingService: IndexingService? {
    modelManager.indexingService
  }

  /// Shorten the path for display: /Users/tristan/.../DirName
  private var shortenedPath: String {
    let path = directory.path
    let components = path.split(separator: "/")
    guard components.count > 3 else { return path }
    return "/\(components[0])/\(components[1])/\u{2026}/\(components.last ?? "")"
  }

  var body: some View {
    HStack(alignment: .center, spacing: 10) {
      Image(systemName: "folder.fill")
        .foregroundStyle(.secondary)
        .font(.title3)

      VStack(alignment: .leading, spacing: 4) {
        // Top line: directory name + shortened path
        HStack(spacing: 6) {
          Text(directory.label ?? URL(fileURLWithPath: directory.path).lastPathComponent)
            .fontWeight(.medium)
          Text("(\(shortenedPath))")
            .font(.caption)
            .foregroundStyle(.tertiary)
            .lineLimit(1)
            .truncationMode(.middle)
        }

        // Bottom line: indexing progress
        IndexingProgressView(directory: directory)
      }

      Spacer()

      // Reindex button
      Button {
        indexingService?.indexDirectory(directory)
      } label: {
        Image(systemName: "arrow.clockwise")
      }
      .buttonStyle(.borderless)
      .disabled(indexingService == nil || indexingService?.isIndexing == true)
      .help("Reindex directory")

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
    .padding(.vertical, 6)
  }
}
