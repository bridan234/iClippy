import SwiftUI

struct FooterView: View {
    let onClearAll: () -> Void
    @AppStorage(LoginItemManager.startAtLoginKey) private var startAtLogin = true

    var body: some View {
        VStack(spacing: 4) {
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
                .padding(.leading, 12)

                Spacer()

                Text("⌘⇧V")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)
                    .padding(.trailing, 12)
            }

            HStack {
                Text("Start at login")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)

                Toggle("", isOn: $startAtLogin)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .controlSize(.mini)
                    .onChange(of: startAtLogin) { newValue in
                        LoginItemManager.setStartAtLogin(newValue)
                    }
            }
            .padding(.bottom, 4)
        }
        .padding(.vertical, 4)
        .background(Color(NSColor.controlBackgroundColor))
    }
}
