import SwiftUI

@main
struct MnemonicApp: App {
  
  @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  
  var body: some Scene {
    // All UI is managed by AppDelegate (status item, search panel, settings window).
    // This minimal Settings scene satisfies SwiftUI's requirement for at least one scene.
    Settings { EmptyView() }
  }
}
