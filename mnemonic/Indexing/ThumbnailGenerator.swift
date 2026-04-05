import AppKit

nonisolated enum ThumbnailError: Error {
    case cannotLoadImage
    case cannotEncodeJPEG
}

nonisolated enum ThumbnailGenerator {

    static let thumbnailsDirectory: URL = {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first!
        return appSupport
            .appendingPathComponent("com.lgx.mnemonic", isDirectory: true)
            .appendingPathComponent("thumbnails", isDirectory: true)
    }()

    /// Generate a 256×256 max JPEG thumbnail. Returns the file path.
    /// Skips generation if a thumbnail for this content hash already exists.
    static func generateThumbnail(for imageURL: URL, contentHash: String) throws -> String {
        let fm = FileManager.default
        try fm.createDirectory(at: thumbnailsDirectory, withIntermediateDirectories: true)

        let thumbURL = thumbnailsDirectory.appendingPathComponent("\(contentHash).jpg")

        // Content-addressed: skip if already exists
        if fm.fileExists(atPath: thumbURL.path) {
            return thumbURL.path
        }

        guard let image = NSImage(contentsOf: imageURL) else {
            throw ThumbnailError.cannotLoadImage
        }

        let size = image.size
        let maxDim: CGFloat = 256
        let scale = min(maxDim / size.width, maxDim / size.height, 1.0)
        let newSize = NSSize(width: (size.width * scale).rounded(), height: (size.height * scale).rounded())

        let thumbImage = NSImage(size: newSize)
        thumbImage.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        image.draw(
            in: NSRect(origin: .zero, size: newSize),
            from: NSRect(origin: .zero, size: size),
            operation: .copy,
            fraction: 1.0
        )
        thumbImage.unlockFocus()

        guard let tiffData = thumbImage.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let jpegData = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.8])
        else {
            throw ThumbnailError.cannotEncodeJPEG
        }

        try jpegData.write(to: thumbURL)
        return thumbURL.path
    }
}
