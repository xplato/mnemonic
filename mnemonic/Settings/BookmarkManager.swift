import Foundation

nonisolated enum BookmarkManager {
  
  static func createBookmark(for url: URL) throws -> Data {
    try url.bookmarkData(
      options: .withSecurityScope,
      includingResourceValuesForKeys: nil,
      relativeTo: nil
    )
  }
  
  static func resolveBookmark(_ data: Data) throws -> (url: URL, isStale: Bool) {
    var isStale = false
    let url = try URL(
      resolvingBookmarkData: data,
      options: .withSecurityScope,
      relativeTo: nil,
      bookmarkDataIsStale: &isStale
    )
    return (url, isStale)
  }
  
  static func startAccessing(_ url: URL) -> Bool {
    url.startAccessingSecurityScopedResource()
  }
  
  static func stopAccessing(_ url: URL) {
    url.stopAccessingSecurityScopedResource()
  }
}
