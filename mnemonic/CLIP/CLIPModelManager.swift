import Foundation
import Observation

@Observable
final class CLIPModelManager {

    private(set) var isDownloading = false
    private(set) var downloadProgress: Double = 0
    private(set) var downloadStatus: String = ""
    private(set) var modelsReady = false

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
        let (asyncBytes, response) = try await URLSession.shared.bytes(from: url)

        let totalBytes = (response as? HTTPURLResponse)
            .flatMap { Int64($0.value(forHTTPHeaderField: "Content-Length") ?? "") } ?? 0

        var data = Data()
        if totalBytes > 0 {
            data.reserveCapacity(Int(totalBytes))
        }

        var downloadedBytes: Int64 = 0
        let progressUpdateThreshold: Int64 = 1_048_576 // 1MB

        for try await byte in asyncBytes {
            data.append(byte)
            downloadedBytes += 1

            if downloadedBytes % progressUpdateThreshold == 0 {
                let fileProgress = totalBytes > 0 ? Double(downloadedBytes) / Double(totalBytes) : 0
                let overallProgress = (Double(fileIndex) + fileProgress) / Double(totalFiles)
                downloadProgress = overallProgress

                if totalBytes > 0 {
                    let mb = downloadedBytes / 1_048_576
                    let totalMb = totalBytes / 1_048_576
                    downloadStatus = "Downloading \(modelFiles[fileIndex].label)... \(mb)/\(totalMb) MB"
                }
            }
        }

        try data.write(to: destination)
        downloadProgress = Double(fileIndex + 1) / Double(totalFiles)
    }
}
