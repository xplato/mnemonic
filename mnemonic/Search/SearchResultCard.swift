import SwiftUI

struct SearchResultCard: View {
  let result: SearchResult
  @State private var isHovering = false
  
  var body: some View {
    VStack(spacing: 4) {
      // Thumbnail
      if let thumbPath = result.thumbnailPath,
         let nsImage = NSImage(contentsOfFile: thumbPath) {
        Image(nsImage: nsImage)
          .resizable()
          .aspectRatio(contentMode: .fill)
          .frame(height: 110)
          .clipped()
          .clipShape(RoundedRectangle(cornerRadius: 6))
      } else {
        RoundedRectangle(cornerRadius: 6)
          .fill(.quaternary)
          .frame(height: 110)
          .overlay {
            Image(systemName: "photo")
              .font(.title2)
              .foregroundStyle(.secondary)
          }
      }
      
      // File info
      HStack(spacing: 4) {
        Text(result.filename)
          .font(.caption)
          .lineLimit(1)
          .truncationMode(.middle)
          .foregroundStyle(isHovering ? .primary : .secondary)
        Spacer(minLength: 0)
        RelevanceBadge(relevance: result.relevance)
      }
    }
    .padding(6)
    .background(
      RoundedRectangle(cornerRadius: 8)
        .fill(isHovering ? .white.opacity(0.08) : .clear)
    )
    .onHover { hovering in
      isHovering = hovering
    }
    .onTapGesture {
      revealInFinder()
    }
    .help(result.path)
  }
  
  private func revealInFinder() {
    let url = URL(fileURLWithPath: result.path)
    NSWorkspace.shared.activateFileViewerSelecting([url])
  }
}
