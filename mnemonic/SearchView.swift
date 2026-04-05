import SwiftUI

struct SearchView: View {

    @State private var query: String = ""
    @FocusState private var isSearchFocused: Bool

    /// Called when the panel should be dismissed.
    var onDismiss: () -> Void = {}

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.secondary)

            TextField("Search files...", text: $query)
                .textFieldStyle(.plain)
                .font(.system(size: 18))
                .focused($isSearchFocused)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .onAppear {
            isSearchFocused = true
        }
        .onKeyPress(.escape) {
            if query.isEmpty {
                onDismiss()
            } else {
                query = ""
            }
            return .handled
        }
    }
}

#Preview {
    SearchView()
        .frame(width: 600)
        .background(.ultraThinMaterial)
}
