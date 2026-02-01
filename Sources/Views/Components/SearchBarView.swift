import SwiftUI

struct SearchBarView: View {
    @Binding var text: String
    var onEscape: () -> Void = {}
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .font(.system(size: 14))

            TextField("Search clipboard...", text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .focused($isFocused)
                .onSubmit {
                    // Allow search to work, don't close on enter
                }

            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.system(size: 14))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
        .onAppear {
            // Auto-focus search bar when popover opens
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isFocused = true
            }
        }
    }
}
