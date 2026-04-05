import SwiftUI

struct SearchView: View {

  @State private var query: String = ""
  @FocusState private var isSearchFocused: Bool
  @Environment(SearchController.self) private var searchController
  @Environment(CLIPModelManager.self) private var modelManager

  var onDismiss: () -> Void = {}
  var onHeightChange: (CGFloat) -> Void = { _ in }
  var onOpenSettings: () -> Void = {}

  private var indexingService: IndexingService? {
    modelManager.indexingService
  }

  /// Current results area height, derived from the shared calculation.
  private var resultsHeight: CGFloat {
    let total = SearchController.contentHeight(
      hasSearched: searchController.hasSearched,
      resultCount: searchController.results.count
    )
    // Subtract search bar + divider to get just the results portion
    return max(0, total - 57)
  }

  var body: some View {
    VStack(spacing: 0) {
      // Search bar
      HStack(spacing: 12) {
        Image(systemName: "magnifyingglass")
          .font(.system(size: 18, weight: .medium))
          .foregroundStyle(.secondary)

        TextField("Search your files...", text: $query)
          .textFieldStyle(.plain)
          .font(.system(size: 18))
          .focused($isSearchFocused)

        if searchController.isSearching {
          ProgressView()
            .scaleEffect(0.6)
        }

        // Indexing indicator
        if let indexingService, indexingService.isIndexing {
          Button {
            onOpenSettings()
          } label: {
            IndexingIndicator(progress: indexingService.progress)
          }
          .buttonStyle(.plain)
          .help("Indexing in progress — click to view details")
        }

        // Settings button
        Button {
          onOpenSettings()
        } label: {
          Image(systemName: "gearshape")
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .help("Settings")
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 14)

      // Results
      if !searchController.results.isEmpty || searchController.hasSearched {
        Divider()
        SearchResultsView(results: searchController.results)
          .frame(height: resultsHeight)
          .clipped()
          .transition(.opacity)
      }
    }
    .animation(.easeOut(duration: 0.25), value: searchController.hasSearched)
    .animation(.easeOut(duration: 0.25), value: searchController.results.count)
    .onAppear {
      isSearchFocused = true
    }
    .onKeyPress(.escape) {
      if query.isEmpty {
        onDismiss()
      } else {
        query = ""
        searchController.clearResults()
      }
      return .handled
    }
    .onChange(of: query) { _, newValue in
      searchController.search(query: newValue)
    }
    .onChange(of: searchController.results.count) { _, newCount in
      notifyHeightChange(resultCount: newCount, hasSearched: searchController.hasSearched)
    }
    .onChange(of: searchController.hasSearched) { _, newValue in
      notifyHeightChange(resultCount: searchController.results.count, hasSearched: newValue)
    }
  }

  private func notifyHeightChange(resultCount: Int, hasSearched: Bool) {
    onHeightChange(SearchController.contentHeight(hasSearched: hasSearched, resultCount: resultCount))
  }
}

/// Compact circular progress indicator for the search bar.
private struct IndexingIndicator: View {
  let progress: IndexingService.IndexingProgress
  
  private var fraction: Double {
    guard progress.total > 0 else { return 0 }
    return Double(progress.processed) / Double(progress.total)
  }
  
  var body: some View {
    ZStack {
      Circle()
        .stroke(.quaternary, lineWidth: 2)
      
      Circle()
        .trim(from: 0, to: fraction)
        .stroke(.blue, style: StrokeStyle(lineWidth: 2, lineCap: .round))
        .rotationEffect(.degrees(-90))
      
      Text("\(progress.processed)")
        .font(.system(size: 7, weight: .medium))
        .foregroundStyle(.secondary)
    }
    .frame(width: 22, height: 22)
    .animation(.easeInOut(duration: 0.3), value: fraction)
  }
}
