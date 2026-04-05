import SwiftUI

struct SettingsView: View {
  @Environment(DirectoryStore.self) private var store
  
  var body: some View {
    VStack(spacing: 0) {
      ModelDownloadView()
      
      Divider()
      
      HStack {
        Text("Indexed Directories")
          .font(.headline)
        Spacer()
        AddDirectoryButton()
      }
      .padding()
      
      Divider()
      
      if store.directories.isEmpty {
        ContentUnavailableView(
          "No Directories",
          systemImage: "folder.badge.plus",
          description: Text("Add a directory to start indexing your files.")
        )
      } else {
        List {
          ForEach(store.directories) { directory in
            DirectoryRowView(directory: directory)
          }
        }
      }
    }
    .frame(minWidth: 500, minHeight: 300)
  }
}
