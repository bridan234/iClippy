import SwiftUI

struct FooterView: View {
    let onClearAll: () -> Void

    var body: some View {
        HStack {
            Text("↑↓ Navigate • ⏎ Copy • ⌫ Delete")
                .font(.system(size: 10))
                .foregroundColor(Color(nsColor: .secondaryLabelColor))

            Spacer()

            Button(action: onClearAll) {
                Text("Clear")
                    .font(.system(size: 10))
                    .foregroundColor(Color(nsColor: .secondaryLabelColor))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(nsColor: .separatorColor)),
            alignment: .top
        )
    }
}
