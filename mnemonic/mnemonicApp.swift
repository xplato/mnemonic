//
//  mnemonicApp.swift
//  mnemonic
//
//  Created by Tristan on 4/4/26.
//

import SwiftUI

@main
struct MnemonicApp: App {

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var directoryStore: DirectoryStore
    @State private var modelManager = CLIPModelManager()
    @State private var indexingService: IndexingService?

    private let database: AppDatabase

    init() {
        let db = try! AppDatabase.makeShared()
        self.database = db
        _directoryStore = State(initialValue: DirectoryStore(database: db))
    }

    var body: some Scene {
        MenuBarExtra("Mnemonic", systemImage: "magnifyingglass") {
            MenuBarView()
                .environment(directoryStore)
                .environment(modelManager)
        }

        Window("Mnemonic Settings", id: "settings") {
            SettingsView()
                .environment(directoryStore)
                .environment(modelManager)
                .environment(indexingService)
                .task {
                    await initializeServicesIfNeeded()
                }
        }
        .defaultSize(width: 600, height: 500)
    }

    /// Initialize CLIP encoders once models are downloaded, then wire up services.
    private func initializeServicesIfNeeded() async {
        modelManager.checkModelsExist()
        guard modelManager.modelsReady else { return }
        guard indexingService == nil else { return }

        do {
            let imageEncoder = try CLIPImageEncoder(modelPath: modelManager.visionModelPath)
            let textEncoder = try await CLIPTextEncoder(
                modelPath: modelManager.textModelPath,
                tokenizerFolder: CLIPModelManager.modelsDirectory
            )

            let idxService = IndexingService(database: database, imageEncoder: imageEncoder)
            let srchService = SearchService(database: database, textEncoder: textEncoder)

            indexingService = idxService
            appDelegate.searchController.searchService = srchService
        } catch {
            print("Failed to initialize CLIP: \(error)")
        }
    }
}
