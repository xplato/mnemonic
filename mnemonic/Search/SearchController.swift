import Foundation
import Observation

@Observable
final class SearchController {
  var searchService: SearchService?
  var database: AppDatabase?
  private(set) var results: [SearchResult] = []
  private(set) var isSearching = false
  private(set) var hasSearched = false
  private(set) var selectedResult: SearchResult?
  
  private var searchTask: Task<Void, Never>?
  
  func search(query: String) {
    searchTask?.cancel()
    
    if searchService == nil {
      print("[Search] searchService is nil — CLIP models may not be initialized yet")
    }
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
        print("[Search] Error searching for '\(query)': \(error)")
        if !Task.isCancelled {
          self.results = []
        }
      }
      self.isSearching = false
      self.hasSearched = true
    }
  }
  
  func selectResult(_ result: SearchResult) {
    selectedResult = result
  }
  
  func deselectResult() {
    selectedResult = nil
  }
  
  func clearResults() {
    searchTask?.cancel()
    results = []
    isSearching = false
    hasSearched = false
    selectedResult = nil
  }

  // MARK: - Panel Height

  private static let searchBarHeight: CGFloat = 56
  private static let maxResultsHeight: CGFloat = 500

  private static let detailViewHeight: CGFloat = 500

  /// Calculates the panel content height based on search state.
  /// Single source of truth used by both SwiftUI layout and panel resizing.
  static func contentHeight(hasSearched: Bool, resultCount: Int, isDetailView: Bool = false) -> CGFloat {
    if isDetailView {
      return detailViewHeight
    }
    
    var height = searchBarHeight
    guard hasSearched || resultCount > 0 else { return height }

    height += 1 // Divider
    if resultCount == 0 {
      height += 60 // "No matching files" message
    } else {
      let columns = 4
      let rows = ceil(Double(resultCount) / Double(columns))
      height += min(CGFloat(rows) * 174 + 20, maxResultsHeight)
    }
    return height
  }
}
