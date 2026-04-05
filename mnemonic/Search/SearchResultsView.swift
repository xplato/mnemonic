import SwiftUI

struct SearchResultsView: View {
    let results: [SearchResult]

    private let columns = [
        GridItem(.adaptive(minimum: 160), spacing: 8)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(results) { result in
                    SearchResultCard(result: result)
                }
            }
            .padding(12)
        }
    }
}
