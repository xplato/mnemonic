import SwiftUI

struct SearchView: View {

    @State private var query: String = ""
    @FocusState private var isSearchFocused: Bool
    @Environment(SearchController.self) private var searchController

    var onDismiss: () -> Void = {}

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
