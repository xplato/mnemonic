import SwiftUI

struct MenuBarView: View {

    var body: some View {
        Button("Open Search") {
            NSApp.sendAction(#selector(AppDelegate.togglePanel), to: nil, from: nil)
        }
        .keyboardShortcut("f", modifiers: [.command, .shift])
        Divider()
        Button("Settings...") {
            NSApp.sendAction(#selector(AppDelegate.openSettings), to: nil, from: nil)
        }
        .keyboardShortcut(",", modifiers: .command)
        Divider()
        Button("Quit Mnemonic") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q", modifiers: .command)
    }
}
