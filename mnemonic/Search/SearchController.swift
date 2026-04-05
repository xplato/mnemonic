import Foundation
import Observation

@Observable
final class SearchController {
    var searchService: SearchService?
    private(set) var results: [SearchResult] = []
    private(set) var isSearching = false
    private(set) var hasSearched = false

    private var searchTask: Task<Void, Never>?

    func search(query: String) {
        searchTask?.cancel()

        guard let service = searchService, !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            results = []
            isSearching = false
            hasSearched = false
            return
        }

        isSearching = true
        searchTask = Task {
            // Debounce: wait 300ms after last keystroke
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }

            do {
                let r = try await service.search(query: query)
                guard !Task.isCancelled else { return }
                self.results = r
            } catch {
                if !Task.isCancelled {
                    self.results = []
                }
            }
            self.isSearching = false
            self.hasSearched = true
        }
    }

    func clearResults() {
        searchTask?.cancel()
        results = []
        isSearching = false
        hasSearched = false
    }
}
