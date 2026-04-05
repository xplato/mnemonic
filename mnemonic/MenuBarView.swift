import SwiftUI

struct MenuBarView: View {
  
  private var appDelegate: AppDelegate? {
    NSApp.delegate as? AppDelegate
  }
  
  var body: some View {
    Button("Open Search") {
      appDelegate?.togglePanel()
    }
    .keyboardShortcut("f", modifiers: [.command, .shift])
    Divider()
    Button("Settings...") {
      appDelegate?.openSettings()
    }
    .keyboardShortcut(",", modifiers: .command)
    Divider()
    Button("Quit Mnemonic") {
      NSApplication.shared.terminate(nil)
    }
    .keyboardShortcut("q", modifiers: .command)
  }
}
