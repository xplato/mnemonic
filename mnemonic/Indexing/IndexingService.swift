import AppKit
import Foundation
import Observation
import GRDB

@Observable
final class IndexingService {
  
  private(set) var isIndexing = false
  private(set) var currentDirectoryId: Int64?
  private(set) var progress: IndexingProgress = .idle
  
  let database: AppDatabase
  private let imageEncoder: CLIPImageEncoder
  private var currentTask: Task<Void, Never>?
  
  nonisolated struct IndexingProgress: Sendable {
    var total: Int = 0
    var processed: Int = 0
    var status: String = "Idle"
    
    static let idle = IndexingProgress()
  }
  
  init(database: AppDatabase, imageEncoder: CLIPImageEncoder) {
    self.database = database
    self.imageEncoder = imageEncoder
  }
  
  func indexDirectory(_ directory: MnemonicDirectory) {
    guard !isIndexing else { return }
    currentTask?.cancel()
    
    currentDirectoryId = directory.id
    isIndexing = true
    progress = IndexingProgress(total: 0, processed: 0, status: "Scanning...")
    
    currentTask = Task.detached { [weak self] in
      guard let self else { return }
      do {
        try await self.performIndexing(directory)
      } catch is CancellationError {
        await MainActor.run {
          self.progress.status = "Cancelled"
        }
      } catch {
        await MainActor.run {
          self.progress.status = "Error: \(error.localizedDescription)"
        }
      }
      await MainActor.run {
        self.isIndexing = false
        self.currentDirectoryId = nil
      }
    }
  }
  
  func cancel() {
    currentTask?.cancel()
    currentTask = nil
  }
  
  private nonisolated func performIndexing(_ directory: MnemonicDirectory) async throws {
    guard let dirId = directory.id, let bookmark = directory.bookmark else { return }
    
    // Resolve bookmark and start security-scoped access
    let (url, _) = try BookmarkManager.resolveBookmark(bookmark)
    guard BookmarkManager.startAccessing(url) else { return }
    defer { BookmarkManager.stopAccessing(url) }
    
    // Create index job
    let jobId = try await database.dbQueue.write { db -> Int64 in
      var job = IndexJob(
        directoryId: dirId,
        status: "running",
        processedFiles: 0,
        startedAt: Date()
      )
      try job.insert(db)
      return job.id!
    }
    
    // Scan directory
    let scannedFiles = try FileScanner.scan(directory: url)
    
    try await database.dbQueue.write { db in
      try db.execute(
        sql: "UPDATE indexJobs SET totalFiles = ? WHERE id = ?",
        arguments: [scannedFiles.count, jobId]
      )
    }
    await MainActor.run {
      self.progress = IndexingProgress(total: scannedFiles.count, processed: 0, status: "Indexing...")
    }
    
    // Determine which files need processing
    let existingHashes: Set<String> = try await database.dbQueue.read { db in
      let hashes = try String.fetchAll(db, sql: """
                SELECT contentHash FROM files WHERE directoryId = ?
                """, arguments: [dirId])
      return Set(hashes)
    }
    let filesToProcess = scannedFiles.filter { !existingHashes.contains($0.contentHash) }
    
    await MainActor.run {
      self.progress.total = filesToProcess.count
      if filesToProcess.isEmpty {
        self.progress.status = "Up to date"
      }
    }
    
    // Process files in batches of 8
    var processed = 0
    let batchSize = 8
    
    for batchStart in stride(from: 0, to: filesToProcess.count, by: batchSize) {
      try Task.checkCancellation()
      
      let batchEnd = min(batchStart + batchSize, filesToProcess.count)
      let batch = filesToProcess[batchStart..<batchEnd]
      
      for file in batch {
        try Task.checkCancellation()
        
        do {
          try processFile(file, directoryId: dirId)
        } catch {
          print("Failed to index \(file.filename): \(error)")
        }
        
        processed += 1
        let p = processed
        let name = file.filename
        await MainActor.run {
          self.progress.processed = p
          self.progress.status = "Indexing \(name)..."
        }
      }
    }
    
    // Mark job completed
    let finalProcessed = processed
    try await database.dbQueue.write { db in
      try db.execute(
        sql: "UPDATE indexJobs SET status = ?, processedFiles = ?, completedAt = ? WHERE id = ?",
        arguments: ["completed", finalProcessed, Date(), jobId]
      )
    }
    
    // Update directory last indexed date
    try await database.dbQueue.write { db in
      if var dir = try MnemonicDirectory.fetchOne(db, id: dirId) {
        dir.lastIndexedAt = Date()
        try dir.update(db)
      }
    }
    
    await MainActor.run {
      self.progress.status = "Complete (\(finalProcessed) files)"
    }
  }
  
  private nonisolated func processFile(_ file: ScannedFile, directoryId: Int64) throws {
    // 1. Load image
    guard let image = NSImage(contentsOf: file.url) else { return }
    
    // Downscale if too large
    let maxDim: CGFloat = 4096
    let finalImage: NSImage
    if image.size.width > maxDim || image.size.height > maxDim {
      let scale = min(maxDim / image.size.width, maxDim / image.size.height)
      let newSize = NSSize(width: image.size.width * scale, height: image.size.height * scale)
      finalImage = NSImage(size: newSize)
      finalImage.lockFocus()
      image.draw(in: NSRect(origin: .zero, size: newSize))
      finalImage.unlockFocus()
    } else {
      finalImage = image
    }
    
    // 2. CLIP preprocess + encode
    guard let tensorData = ImagePreprocessor.preprocess(finalImage) else { return }
    let embedding = try imageEncoder.encode(pixelValues: tensorData)
    
    // 3. Generate thumbnail
    let thumbnailPath = try ThumbnailGenerator.generateThumbnail(
      for: file.url, contentHash: file.contentHash
    )
    
    // 4. Persist to database
    let embeddingData = embedding.withUnsafeBufferPointer { Data(buffer: $0) }
    
    try database.dbQueue.write { db in
      var indexedFile = IndexedFile(
        path: file.url.path,
        directoryId: directoryId,
        filename: file.filename,
        fileExtension: file.fileExtension,
        sizeBytes: file.sizeBytes,
        modifiedAt: file.modifiedAt,
        contentHash: file.contentHash,
        mimeType: nil,
        width: Int(finalImage.size.width),
        height: Int(finalImage.size.height),
        indexedAt: Date(),
        thumbnailPath: thumbnailPath
      )
      try indexedFile.save(db)
      
      guard let fileId = indexedFile.id else { return }
      
      let fileEmbedding = FileEmbedding(fileId: fileId, embedding: embeddingData)
      try fileEmbedding.insert(db)
    }
  }
}
