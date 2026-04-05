import Foundation
import CryptoKit

nonisolated struct ScannedFile: Sendable {
  let url: URL
  let filename: String
  let fileExtension: String
  let sizeBytes: Int64
  let modifiedAt: Date
  let contentHash: String
}

nonisolated enum FileScanner {
  
  static let supportedExtensions: Set<String> = [
    "jpg", "jpeg", "png", "gif", "webp", "bmp", "tiff", "tif", "svg", "heic"
  ]
  
  /// Walk directory recursively and return all supported image files with their hashes.
  static func scan(directory: URL) throws -> [ScannedFile] {
    let fm = FileManager.default
    guard let enumerator = fm.enumerator(
      at: directory,
      includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey, .isRegularFileKey],
      options: [.skipsHiddenFiles]
    ) else { return [] }
    
    var results: [ScannedFile] = []
    
    for case let fileURL as URL in enumerator {
      let ext = fileURL.pathExtension.lowercased()
      guard supportedExtensions.contains(ext) else { continue }
      
      let resourceValues = try fileURL.resourceValues(
        forKeys: [.fileSizeKey, .contentModificationDateKey, .isRegularFileKey]
      )
      guard resourceValues.isRegularFile == true else { continue }
      
      let size = Int64(resourceValues.fileSize ?? 0)
      let modified = resourceValues.contentModificationDate ?? Date()
      let hash = try hashFile(at: fileURL)
      
      results.append(ScannedFile(
        url: fileURL,
        filename: fileURL.lastPathComponent,
        fileExtension: ext,
        sizeBytes: size,
        modifiedAt: modified,
        contentHash: hash
      ))
    }
    
    return results
  }
  
  /// SHA256 hash of file contents as lowercase hex string.
  private static func hashFile(at url: URL) throws -> String {
    let data = try Data(contentsOf: url)
    let digest = SHA256.hash(data: data)
    return digest.map { String(format: "%02x", $0) }.joined()
  }
}
