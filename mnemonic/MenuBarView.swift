import SwiftUI

struct MenuBarView: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("Toggle Search") {
            NSApp.sendAction(#selector(AppDelegate.togglePanel), to: nil, from: nil)
        }
        .keyboardShortcut("f", modifiers: [.command, .shift])
        Divider()
        Button("Settings...") {
            NSApp.activate()
            openWindow(id: "settings")
        }
        .keyboardShortcut(",", modifiers: .command)
        Divider()
        Button("Quit Mnemonic") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q", modifiers: .command)
    }
}
