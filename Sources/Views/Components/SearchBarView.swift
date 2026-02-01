import SwiftUI

struct SearchBarView: View {
    @Binding var searchQuery: String
    @FocusState var isSearchFocused: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Color(nsColor: .secondaryLabelColor))
                .font(.system(size: 13))

            TextField("Search clipboard history...", text: $searchQuery)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .foregroundColor(Color(nsColor: .labelColor))
                .focused($isSearchFocused)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
        )
    }
}
