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

    init() {
        let database = try! AppDatabase.makeShared()
        _directoryStore = State(initialValue: DirectoryStore(database: database))
    }

    var body: some Scene {
        MenuBarExtra("Mnemonic", systemImage: "magnifyingglass") {
            MenuBarView()
                .environment(directoryStore)
        }

        Window("Mnemonic Settings", id: "settings") {
            SettingsView()
                .environment(directoryStore)
        }
        .defaultSize(width: 600, height: 400)
    }
}
