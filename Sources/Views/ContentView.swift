import SwiftUI
import AppKit

struct ContentView: View {
    @EnvironmentObject var clipboardManager: ClipboardManager
    @Environment(\.pasteHandler) var pasteHandler
    @ObservedObject private var settings = AppSettings.shared
    @State private var searchText = ""
    @State private var typeFilter = "all"
    @State private var appFilter = "all"
    @State private var pinnedOnly = false
    @State private var snippetsOnly = false
    @State private var selectedID: UUID?
    @State private var keyboardMonitor: Any?
    @State private var editor: ClipboardEntry?
    @State private var newSnippet = false

    var filteredEntries: [ClipboardEntry] {
        clipboardManager.entries.filter {
            (searchText.isEmpty || $0.searchableText.localizedCaseInsensitiveContains(searchText)) &&
            (typeFilter == "all" || $0.type.rawValue == typeFilter) &&
            (appFilter == "all" || $0.sourceBundleID == appFilter) &&
            (!pinnedOnly || $0.isPinned) && (!snippetsOnly || $0.isSnippet)
        }
    }
    var selectedEntry: ClipboardEntry? {
        filteredEntries.first { $0.id == selectedID } ?? filteredEntries.first
    }
    var sourceApps: [(String, String)] {
        var names: [String: String] = [:]
        for e in clipboardManager.entries {
            if let id = e.sourceBundleID { names[id] = e.sourceAppName ?? id }
        }
        return names.map { ($0.key, $0.value) }.sorted { $0.1 < $1.1 }
    }
    var body: some View {
        VStack(spacing: 0) {
            SearchBarView(text: $searchText)
            HStack {
                Picker("Type", selection: $typeFilter) {
                    Text("All types").tag("all")
                    Text("Text").tag("text"); Text("Rich text").tag("richText")
                    Text("Images").tag("image"); Text("Code").tag("code")
                }.labelsHidden()
                Picker("Source app", selection: $appFilter) {
                    Text("All apps").tag("all")
                    ForEach(sourceApps, id: \.0) { id, name in Text(name).tag(id) }
                }.labelsHidden()
            }.padding(.horizontal, 10)
            HStack {
                Toggle("Pinned", isOn: $pinnedOnly)
                Toggle("Snippets", isOn: $snippetsOnly)
                Spacer()
                Button { newSnippet = true } label: { Image(systemName: "plus") }.help("New named snippet")
            }.toggleStyle(.checkbox).padding(10)
            if settings.privateMode {
                Text("Private mode: clipboard recording is paused").font(.caption).foregroundColor(.orange).padding(6)
            }
            if let message = clipboardManager.statusMessage {
                HStack {
                    Text(message).font(.caption)
                    Button { clipboardManager.statusMessage = nil } label: { Image(systemName: "xmark") }
                }.padding(8).foregroundColor(.orange)
            }
            Divider()
            if filteredEntries.isEmpty {
                EmptyStateView(isSearching: !searchText.isEmpty || typeFilter != "all" || appFilter != "all" || pinnedOnly || snippetsOnly)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(filteredEntries) { entry in
                                ClipboardItemView(entry: entry, isSelected: selectedEntry?.id == entry.id,
                                    onPaste: { pasteHandler(entry, false) },
                                    onPlainPaste: { pasteHandler(entry, true) },
                                    onCopy: { clipboardManager.copyToClipboard(entry) },
                                    onPin: { clipboardManager.togglePin(entry) },
                                    onDelete: { clipboardManager.deleteEntry(entry) },
                                    onSnippet: { editor = entry })
                                .onHover { if $0 { selectedID = entry.id } }.id(entry.id)
                                Divider()
                            }
                        }
                    }.onChange(of: selectedID) { id in if let id { proxy.scrollTo(id, anchor: .center) } }
                }
            }
            Divider()
            HStack {
                Button("Clear unpinned") { clipboardManager.clearUnpinned() }
                    .help("Keeps pinned items and named snippets")
                Spacer()
                Button { NotificationCenter.default.post(name: .iClippySettings, object: nil) } label: { Image(systemName: "gearshape") }
                Text(settings.shortcutLabel).font(.system(.caption, design: .monospaced)).foregroundColor(.secondary)
            }.buttonStyle(.plain).padding(10)
        }
        .frame(width: 400, height: 570)
        .background(VisualEffectView(material: .popover, blendingMode: .behindWindow))
        .onAppear { installKeyboardMonitor() }
        .onDisappear { if let keyboardMonitor { NSEvent.removeMonitor(keyboardMonitor) }; keyboardMonitor = nil }
        .onChange(of: searchText) { _ in selectedID = nil }
        .onChange(of: typeFilter) { _ in selectedID = nil }
        .onChange(of: appFilter) { _ in selectedID = nil }
        .sheet(isPresented: $newSnippet) {
            SnippetEditor(entryID: nil, onSave: clipboardManager.saveSnippet, name: "", text: "")
        }
        .sheet(item: $editor) { entry in
            SnippetEditor(entryID: entry.isSnippet ? entry.id : nil, onSave: clipboardManager.saveSnippet,
                name: entry.snippetName ?? "", text: entry.content)
        }
    }
    private func installKeyboardMonitor() {
        guard keyboardMonitor == nil else { return }
        keyboardMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard NSApp.keyWindow?.identifier?.rawValue == "iClippyPopover", editor == nil, !newSnippet else { return event }
            if event.keyCode == 53 { NSApp.sendAction(#selector(AppDelegate.togglePopover), to: nil, from: nil); return nil }
            guard !filteredEntries.isEmpty else { return event }
            if event.keyCode == 36, let entry = selectedEntry {
                pasteHandler(entry, event.modifierFlags.contains(.shift)); return nil
            }
            if event.keyCode == 125 || event.keyCode == 126 {
                let index = filteredEntries.firstIndex { $0.id == selectedEntry?.id } ?? 0
                let next = max(0, min(filteredEntries.count - 1, index + (event.keyCode == 125 ? 1 : -1)))
                selectedID = filteredEntries[next].id; return nil
            }
            return event
        }
    }
}
