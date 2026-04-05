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

    var body: some Scene {
        MenuBarExtra("Mnemonic", systemImage: "magnifyingglass") {
            Button("Toggle Search") {
                appDelegate.togglePanel()
            }
            .keyboardShortcut("f", modifiers: [.command, .shift])
            Divider()
            Button("Quit Mnemonic") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        }
    }
}
