import SwiftUI

@main
struct MnemonicApp: App {

  @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  @State private var isReady = false

  var body: some Scene {
    Settings {
      Group {
        if isReady {
          SettingsView()
            .environment(appDelegate.directoryStore as DirectoryStore)
            .environment(appDelegate.modelManager)
        } else {
          ProgressView()
        }
      }
      .frame(minWidth: 600, minHeight: 400)
      .task { isReady = true }
    }
  }
}
