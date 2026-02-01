import SwiftUI

struct EmptyStateView: View {
    let isSearching: Bool

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: isSearching ? "magnifyingglass" : "doc.on.clipboard")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text(isSearching ? "No results found" : "No clipboard history")
                .font(.title3)
                .foregroundColor(.secondary)

            Text(isSearching ? "Try a different search term" : "Copy something to get started")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
