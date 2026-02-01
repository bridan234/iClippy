import SwiftUI

struct EmptyStateView: View {
    let hasSearchQuery: Bool

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.on.clipboard")
                .font(.system(size: 42))
                .foregroundColor(Color(nsColor: .tertiaryLabelColor))

            Text(hasSearchQuery ? "No matching items" : "No clipboard history")
                .font(.system(size: 13))
                .foregroundColor(Color(nsColor: .secondaryLabelColor))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
