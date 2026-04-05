import SwiftUI

@main
struct MnemonicApp: App {

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra("Mnemonic", systemImage: "magnifyingglass") {
            MenuBarView()
        }
    }
}
