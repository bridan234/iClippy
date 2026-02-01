import SwiftUI

struct FooterView: View {
    let onClearAll: () -> Void

    var body: some View {
        HStack {
            Button(action: onClearAll) {
                HStack(spacing: 4) {
                    Image(systemName: "trash")
                        .font(.system(size: 11))
                    Text("Clear All")
                        .font(.system(size: 11))
                }
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)

            Spacer()

            Text("⌘⇧V")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
        }
        .frame(height: 28)
        .background(Color(NSColor.controlBackgroundColor))
    }
}
