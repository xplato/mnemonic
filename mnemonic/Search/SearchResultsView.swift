import SwiftUI

struct SearchResultsView: View {
  let results: [SearchResult]
  var heroNamespace: Namespace.ID
  
  private let columns = [
    GridItem(.adaptive(minimum: 160, maximum: 200), spacing: 6)
  ]
  
  var body: some View {
    ScrollView {
      if results.isEmpty {
        Text("No matching files found")
          .foregroundStyle(.tertiary)
          .font(.callout)
          .padding(.vertical, 24)
          .frame(maxWidth: .infinity)
      } else {
        LazyVGrid(columns: columns, spacing: 6) {
          ForEach(results) { result in
            SearchResultCard(result: result, heroNamespace: heroNamespace)
          }
        }
        .padding(10)
      }
    }
  }
}
