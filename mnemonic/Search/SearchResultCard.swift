import SwiftUI

struct SearchResultCard: View {
    let result: SearchResult

    var body: some View {
        VStack(spacing: 4) {
            if let thumbPath = result.thumbnailPath,
               let nsImage = NSImage(contentsOfFile: thumbPath) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 160, height: 120)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(.quaternary)
                    .frame(width: 160, height: 120)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    }
            }

            HStack {
                Text(result.filename)
                    .font(.caption)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
                RelevanceBadge(relevance: result.relevance)
            }
        }
        .frame(width: 160)
        .padding(6)
        .background(.ultraThinMaterial.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
