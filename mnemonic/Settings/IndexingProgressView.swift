import SwiftUI

struct IndexingProgressView: View {
    @Environment(CLIPModelManager.self) private var modelManager
    let directory: MnemonicDirectory

    private var indexingService: IndexingService? {
        modelManager.indexingService
    }

    private var isIndexingThis: Bool {
        guard let indexingService else { return false }
        return indexingService.isIndexing && indexingService.currentDirectoryId == directory.id
    }

    var body: some View {
        if let indexingService {
            if isIndexingThis {
                VStack(alignment: .leading, spacing: 2) {
                    ProgressView(
                        value: Double(indexingService.progress.processed),
                        total: Double(max(indexingService.progress.total, 1))
                    )
                    Text(indexingService.progress.status)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } else {
                Button("Index Now") {
                    indexingService.indexDirectory(directory)
                }
                .buttonStyle(.borderless)
                .font(.caption)
            }
        } else {
            Text("Models required")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }
}
