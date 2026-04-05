import SwiftUI

struct ModelDownloadView: View {
  @Environment(CLIPModelManager.self) private var modelManager
  
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Text("CLIP Models")
          .font(.headline)
        Spacer()
        if modelManager.modelsReady {
          Label("Ready", systemImage: "checkmark.circle.fill")
            .foregroundStyle(.green)
            .font(.caption)
        }
      }
      
      if !modelManager.modelsReady && !modelManager.isDownloading {
        Text("Models need to be downloaded (~608 MB total)")
          .font(.caption)
          .foregroundStyle(.secondary)
        Button("Download Models") {
          Task {
            try? await modelManager.downloadModels()
            // Initialize CLIP services now that models are available
            if let delegate = NSApp.delegate as? AppDelegate {
              await delegate.initializeServicesIfNeeded()
            }
          }
        }
      }
      
      if modelManager.isDownloading {
        VStack(alignment: .leading, spacing: 4) {
          ProgressView(value: modelManager.downloadProgress)
          Text(modelManager.downloadStatus)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
    }
    .padding()
    .onAppear {
      modelManager.checkModelsExist()
    }
  }
}
