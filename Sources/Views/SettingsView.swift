import SwiftUI
import AppKit

extension Notification.Name {
    static let iClippySettings = Notification.Name("iClippySettings")
    static let iClippyShortcut = Notification.Name("iClippyShortcut")
}

struct SettingsView: View {
    @ObservedObject private var settings = AppSettings.shared
    @State private var recording = false
    @State private var monitor: Any?

    var body: some View {
        Form {
            Section(header: Text("Privacy")) {
                Toggle("Private mode — stop recording clipboard changes", isOn: $settings.privateMode)
                Text("Excluded app bundle IDs (one per line)")
                TextEditor(text: $settings.excludedApps)
                    .font(.system(.body, design: .monospaced)).frame(height: 90)
                    .border(Color.secondary.opacity(0.3))
                Text("Password-manager privacy markers are always respected. History and images are encrypted locally using a key in your Keychain.")
                    .font(.caption).foregroundColor(.secondary)
            }
            Section(header: Text("History")) {
                Stepper("Keep ordinary history for \(settings.retentionDays) days", value: $settings.retentionDays, in: 1...90)
                Stepper("History limit: \(settings.maxEntries) items", value: $settings.maxEntries, in: 50...5000, step: 50)
                Stepper("History size: \(settings.maxStorageMB) MB", value: $settings.maxStorageMB, in: 10...1000, step: 10)
                Text("Pinned items and named snippets never expire and are exempt from automatic limits. Captured items over 10 MB are skipped.")
                    .font(.caption).foregroundColor(.secondary)
            }
            Section(header: Text("Images")) {
                Toggle("Recognize text in images for search (on this Mac)", isOn: $settings.recognizeImages)
            }
            Section(header: Text("Keyboard shortcut")) {
                HStack {
                    Button(recording ? "Press a shortcut… (Esc cancels)" : "Change \(settings.shortcutLabel)") { beginRecording() }
                    Button("Reset to ⌘⇧V") { requestShortcut(code: 9, modifiers: [.command, .shift], label: "⌘⇧V") }
                }
                Text("Use Command, Control, or Option plus a letter, number, or key.").font(.caption).foregroundColor(.secondary)
                if !settings.shortcutError.isEmpty { Text(settings.shortcutError).foregroundColor(.red).font(.caption) }
            }
        }
        .padding(20).frame(width: 520)
        .onDisappear { stopRecording() }
    }
    private func beginRecording() {
        stopRecording(); recording = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 53 { stopRecording(); return nil }
            let flags = event.modifierFlags.intersection([.command, .control, .option, .shift])
            guard !flags.intersection([.command, .control, .option]).isEmpty else {
                settings.shortcutError = "Include Command, Control, or Option."; return nil
            }
            let prefix = (flags.contains(.control) ? "⌃" : "") + (flags.contains(.option) ? "⌥" : "") + (flags.contains(.shift) ? "⇧" : "") + (flags.contains(.command) ? "⌘" : "")
            requestShortcut(code: Int(event.keyCode), modifiers: flags, label: prefix + (event.charactersIgnoringModifiers?.uppercased() ?? "Key \(event.keyCode)"))
            stopRecording(); return nil
        }
    }
    private func stopRecording() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil; recording = false
    }
    private func requestShortcut(code: Int, modifiers: NSEvent.ModifierFlags, label: String) {
        NotificationCenter.default.post(name: .iClippyShortcut, object: nil,
            userInfo: ["code": code, "modifiers": modifiers.rawValue, "label": label])
    }
}

struct SnippetEditor: View {
    @Environment(\.dismiss) private var dismiss
    let entryID: UUID?
    let onSave: (String, String, UUID?) -> Void
    @State var name: String
    @State var text: String
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(entryID == nil ? "New snippet" : "Edit snippet").font(.headline)
            TextField("Snippet name", text: $name)
            TextEditor(text: $text).font(.system(.body, design: .monospaced)).frame(minHeight: 180)
            HStack {
                Button("Cancel") { dismiss() }.keyboardShortcut(.cancelAction)
                Spacer()
                Button("Save") { onSave(name, text, entryID); dismiss() }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || text.isEmpty || text.utf8.count > ClipboardManager.maxItemBytes)
                    .keyboardShortcut(.defaultAction)
            }
        }.padding().frame(width: 430)
    }
}
