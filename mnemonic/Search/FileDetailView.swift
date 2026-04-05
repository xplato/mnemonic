import SwiftUI
import GRDB
import Quartz

struct FileDetailView: View {
    let result: SearchResult
    let database: AppDatabase
    let searchService: SearchService?
    var onBack: () -> Void = {}
    var onSelectResult: (SearchResult) -> Void = { _ in }
    
    @State private var fileInfo: IndexedFile?
    @State private var similarFiles: [SearchResult] = []
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack(spacing: 8) {
                Button {
                    onBack()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Back to results")
                
                Text(result.filename)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                    .truncationMode(.middle)
                
                Spacer()
                
                Button {
                    openQuickLook()
                } label: {
                    Image(systemName: "eye")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Quick Look (Space)")
                
                Button {
                    revealInFinder()
                } label: {
                    Image(systemName: "folder")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Reveal in Finder")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            
            Divider()
            
            // Main content
            HStack(alignment: .top, spacing: 16) {
                // Image preview (left, ~60%)
                imagePreview
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                
                // Metadata (right, ~40%)
                metadataPanel
                    .frame(width: 220)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, similarFiles.isEmpty ? 16 : 8)
            
            // Similar files
            if !similarFiles.isEmpty {
                similarFilesSection
            }
        }
        .onKeyPress(.space) {
            openQuickLook()
            return .handled
        }
        .task {
            await loadFileInfo()
            await loadSimilarFiles()
        }
    }
    
    // MARK: - Image Preview
    
    @ViewBuilder
    private var imagePreview: some View {
        if let thumbPath = result.thumbnailPath,
           let nsImage = NSImage(contentsOfFile: thumbPath) {
            Image(nsImage: nsImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 6))
        } else {
            RoundedRectangle(cornerRadius: 6)
                .fill(.quaternary)
                .overlay {
                    Image(systemName: "photo")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                }
        }
    }
    
    // MARK: - Metadata Panel
    
    private var metadataPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            metadataRow("Name", value: result.filename)
            
            if let info = fileInfo {
                if let ext = info.fileExtension {
                    metadataRow("Type", value: ext.uppercased())
                }
                
                if let w = info.width, let h = info.height {
                    metadataRow("Dimensions", value: "\(w) × \(h)")
                }
                
                metadataRow("Size", value: formatFileSize(info.sizeBytes))
                
                metadataRow("Modified", value: formatDate(info.modifiedAt))
                
                if let mime = info.mimeType {
                    metadataRow("MIME Type", value: mime)
                }
            }
            
            metadataRow("Path", value: result.path)
            
            Spacer()
        }
        .padding(.top, 4)
    }
    
    private func metadataRow(_ label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.tertiary)
            Text(value)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .truncationMode(.middle)
                .textSelection(.enabled)
        }
    }
    
    // MARK: - Similar Files
    
    private var similarFilesSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Similar files")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 16)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(similarFiles) { similar in
                        similarFileCard(similar)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.bottom, 12)
    }
    
    private func similarFileCard(_ file: SearchResult) -> some View {
        VStack(spacing: 4) {
            if let thumbPath = file.thumbnailPath,
               let nsImage = NSImage(contentsOfFile: thumbPath) {
                Color.clear
                    .frame(width: 100, height: 80)
                    .overlay(alignment: .top) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 4))
            } else {
                RoundedRectangle(cornerRadius: 4)
                    .fill(.quaternary)
                    .frame(width: 100, height: 80)
                    .overlay {
                        Image(systemName: "photo")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
            }
            
            Text(file.filename)
                .font(.system(size: 10))
                .lineLimit(1)
                .truncationMode(.middle)
                .foregroundStyle(.secondary)
                .frame(width: 100)
        }
        .onTapGesture {
            onSelectResult(file)
        }
    }
    
    // MARK: - Data Loading
    
    private func loadFileInfo() async {
        do {
            let fileId = result.id
            let info: IndexedFile? = try await database.dbQueue.read { db in
                try IndexedFile.fetchOne(db, id: fileId)
            }
            self.fileInfo = info
        } catch {
            print("[FileDetail] Failed to load file info: \(error)")
        }
    }
    
    private func loadSimilarFiles() async {
        guard let service = searchService else { return }
        do {
            let similar = try await service.findSimilar(toFileId: result.id)
            self.similarFiles = similar
        } catch {
            print("[FileDetail] Failed to load similar files: \(error)")
        }
    }
    
    // MARK: - Quick Look
    
    private func openQuickLook() {
        let coordinator = QuickLookCoordinator.shared
        coordinator.previewURL = URL(fileURLWithPath: result.path) as NSURL
        
        if let panel = QLPreviewPanel.shared() {
            panel.dataSource = coordinator
            if panel.isVisible {
                panel.reloadData()
            } else {
                panel.makeKeyAndOrderFront(nil)
            }
        }
    }
    
    // MARK: - Helpers
    
    private func revealInFinder() {
        let url = URL(fileURLWithPath: result.path)
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
    
    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Quick Look Coordinator

final class QuickLookCoordinator: NSObject, QLPreviewPanelDataSource {
    static let shared = QuickLookCoordinator()
    var previewURL: NSURL?
    
    func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int {
        previewURL != nil ? 1 : 0
    }
    
    func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> (any QLPreviewItem)! {
        previewURL
    }
    
    func dismiss() {
        if let panel = QLPreviewPanel.shared(), panel.isVisible {
            panel.orderOut(nil)
        }
        previewURL = nil
    }
}
