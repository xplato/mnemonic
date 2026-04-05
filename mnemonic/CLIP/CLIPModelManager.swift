import Foundation
import Observation

/// Tracks download progress via URLSessionDelegate callbacks.
private final class DownloadProgressDelegate: NSObject, URLSessionDownloadDelegate, Sendable {
  private let continuation: AsyncStream<(Int64, Int64)>.Continuation
  private let stream: AsyncStream<(Int64, Int64)>
  
  override init() {
    var cont: AsyncStream<(Int64, Int64)>.Continuation!
    stream = AsyncStream { cont = $0 }
    continuation = cont
    super.init()
  }
  
  func progressStream() -> AsyncStream<(Int64, Int64)> { stream }
  
  func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                  didWriteData bytesWritten: Int64, totalBytesWritten: Int64,
                  totalBytesExpectedToWrite: Int64) {
    continuation.yield((totalBytesWritten, totalBytesExpectedToWrite))
  }
  
  func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                  didFinishDownloadingTo location: URL) {
    continuation.finish()
  }
}

@Observable
final class CLIPModelManager {
  
  private(set) var isDownloading = false
  private(set) var downloadProgress: Double = 0
  private(set) var downloadStatus: String = ""
  private(set) var modelsReady = false
  
  /// Set by AppDelegate once CLIP encoders are initialized.
  var indexingService: IndexingService?
  
  static let modelsDirectory: URL = {
    let appSupport = FileManager.default.urls(
      for: .applicationSupportDirectory, in: .userDomainMask
    ).first!
    return appSupport
      .appendingPathComponent("com.lgx.mnemonic", isDirectory: true)
      .appendingPathComponent("models", isDirectory: true)
  }()
  
  var visionModelPath: URL {
    Self.modelsDirectory.appendingPathComponent("clip-vision.onnx")
  }
  
  var textModelPath: URL {
    Self.modelsDirectory.appendingPathComponent("clip-text.onnx")
  }
  
  var tokenizerPath: URL {
    Self.modelsDirectory.appendingPathComponent("tokenizer.json")
  }
  
  var tokenizerConfigPath: URL {
    Self.modelsDirectory.appendingPathComponent("tokenizer_config.json")
  }
  
  private struct ModelFile {
    let url: URL
    let destination: URL
    let label: String
  }
  
  private var modelFiles: [ModelFile] {
    [
      ModelFile(
        url: URL(string: "https://huggingface.co/jmzzomg/clip-vit-base-patch32-vision-onnx/resolve/main/model.onnx")!,
        destination: visionModelPath,
        label: "Vision encoder"
      ),
      ModelFile(
        url: URL(string: "https://huggingface.co/jmzzomg/clip-vit-base-patch32-text-onnx/resolve/main/model.onnx")!,
        destination: textModelPath,
        label: "Text encoder"
      ),
      ModelFile(
        url: URL(string: "https://huggingface.co/jmzzomg/clip-vit-base-patch32-text-onnx/resolve/main/tokenizer.json")!,
        destination: tokenizerPath,
        label: "Tokenizer"
      ),
      ModelFile(
        url: URL(string: "https://huggingface.co/jmzzomg/clip-vit-base-patch32-text-onnx/resolve/main/tokenizer_config.json")!,
        destination: tokenizerConfigPath,
        label: "Tokenizer config"
      ),
    ]
  }
  
  func checkModelsExist() {
    let fm = FileManager.default
    modelsReady = modelFiles.allSatisfy { fm.fileExists(atPath: $0.destination.path) }
  }
  
  func downloadModels() async throws {
    isDownloading = true
    downloadProgress = 0
    defer { isDownloading = false }
    
    let fm = FileManager.default
    try fm.createDirectory(at: Self.modelsDirectory, withIntermediateDirectories: true)
    
    let totalFiles = modelFiles.count
    for (index, file) in modelFiles.enumerated() {
      // Skip if already downloaded
      if fm.fileExists(atPath: file.destination.path) {
        downloadStatus = "\(file.label) already downloaded"
        downloadProgress = Double(index + 1) / Double(totalFiles)
        continue
      }
      
      downloadStatus = "Downloading \(file.label)..."
      try await downloadFile(from: file.url, to: file.destination, fileIndex: index, totalFiles: totalFiles)
    }
    
    downloadStatus = "Models ready"
    downloadProgress = 1.0
    modelsReady = true
  }
  
  private func downloadFile(from url: URL, to destination: URL, fileIndex: Int, totalFiles: Int) async throws {
    // Use a delegate-based download to track progress
    let delegate = DownloadProgressDelegate()
    let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
    defer { session.invalidateAndCancel() }
    
    let label = modelFiles[fileIndex].label
    
    // Observe progress from the delegate
    let progressTask = Task {
      for await (downloaded, total) in delegate.progressStream() {
        let fileProgress = total > 0 ? Double(downloaded) / Double(total) : 0
        let overallProgress = (Double(fileIndex) + fileProgress) / Double(totalFiles)
        await MainActor.run {
          self.downloadProgress = overallProgress
          if total > 0 {
            let mb = downloaded / 1_048_576
            let totalMb = total / 1_048_576
            self.downloadStatus = "Downloading \(label)... \(mb)/\(totalMb) MB"
          }
        }
      }
    }
    
    let (tempURL, _) = try await session.download(from: url)
    progressTask.cancel()
    
    // Move downloaded file to destination
    let fm = FileManager.default
    if fm.fileExists(atPath: destination.path) {
      try fm.removeItem(at: destination)
    }
    try fm.moveItem(at: tempURL, to: destination)
    
    downloadProgress = Double(fileIndex + 1) / Double(totalFiles)
  }
}
