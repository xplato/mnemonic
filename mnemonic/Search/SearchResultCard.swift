import SwiftUI

struct SearchResultCard: View {
  let result: SearchResult
  var heroNamespace: Namespace.ID
  @Environment(SearchController.self) private var searchController
  @State private var isHovering = false
  
  var body: some View {
    VStack(spacing: 4) {
      // Thumbnail
      if let thumbPath = result.thumbnailPath,
         let nsImage = NSImage(contentsOfFile: thumbPath) {
        Color.clear
          .frame(minWidth: 0, maxWidth: .infinity, minHeight: 138, maxHeight: 138)
          .overlay(alignment: .top) {
            Image(nsImage: nsImage)
              .resizable()
              .aspectRatio(contentMode: .fill)
              .frame(minWidth: 0, maxWidth: .infinity)
          }
          .clipShape(RoundedRectangle(cornerRadius: 6))
          .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 6))
          .matchedGeometryEffect(id: result.id, in: heroNamespace)
      } else {
        RoundedRectangle(cornerRadius: 6)
          .fill(.quaternary)
          .frame(height: 138)
          .overlay {
            Image(systemName: "photo")
              .font(.title2)
              .foregroundStyle(.secondary)
          }
          .matchedGeometryEffect(id: result.id, in: heroNamespace)
      }
      
      // File info
      HStack(spacing: 4) {
        Text(result.filename)
          .font(.default)
          .lineLimit(1)
          .truncationMode(.middle)
          .foregroundStyle(isHovering ? .primary : .secondary)
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
      searchController.selectResult(result)
    }
    .help(result.path)
  }
}
