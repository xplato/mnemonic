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
        HStack(spacing: 8) {
          ProgressView(
            value: Double(progress.processed),
            total: Double(max(progress.total, 1))
          )

          Text("\(formatted(progress.processed)) / \(formatted(progress.total)) files")
            .font(.caption)
            .foregroundStyle(.secondary)
            .monospacedDigit()
            .layoutPriority(1)
        }
      } else if indexingService.isIndexing {
        Text("Waiting\u{2026}")
          .font(.caption)
          .foregroundStyle(.tertiary)
      } else if let lastIndexed = directory.lastIndexedAt {
        Text("Indexed \(lastIndexed, format: .relative(presentation: .named))")
          .font(.caption)
          .foregroundStyle(.tertiary)
      } else {
        Text("Not yet indexed")
          .font(.caption)
          .foregroundStyle(.tertiary)
      }
    } else {
      Text("Models required")
        .font(.caption)
        .foregroundStyle(.tertiary)
    }
  }

  private func formatted(_ n: Int) -> String {
    n.formatted(.number)
  }
}
