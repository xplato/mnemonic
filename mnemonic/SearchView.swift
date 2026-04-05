import SwiftUI

struct SearchView: View {

    @State private var query: String = ""
    @FocusState private var isSearchFocused: Bool
    @Environment(SearchController.self) private var searchController
    @Environment(CLIPModelManager.self) private var modelManager

    var onDismiss: () -> Void = {}

    private var indexingService: IndexingService? {
        modelManager.indexingService
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
                        NSApp.sendAction(#selector(AppDelegate.openSettings), to: nil, from: nil)
                    } label: {
                        IndexingIndicator(progress: indexingService.progress)
                    }
                    .buttonStyle(.plain)
                    .help("Indexing in progress — click to view details")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            // Results
            if !searchController.results.isEmpty {
                Divider()
                SearchResultsView(results: searchController.results)
                    .frame(maxHeight: 400)
            }
        }
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
