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
                let progress = indexingService.progress
                VStack(alignment: .leading, spacing: 4) {
                    ProgressView(
                        value: Double(progress.processed),
                        total: Double(max(progress.total, 1))
                    )

                    HStack(spacing: 4) {
                        Text("\(progress.processed)/\(progress.total)")
                            .fontWeight(.medium)
                        Text(progress.status)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }
            } else if indexingService.isIndexing {
                // Another directory is being indexed
                Text("Waiting...")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
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
