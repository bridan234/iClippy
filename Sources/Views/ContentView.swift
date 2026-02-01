import SwiftUI
import AppKit

// Extension to handle keyboard events
extension View {
    func onKeyDown(perform action: @escaping (NSEvent) -> Bool) -> some View {
        self.background(KeyEventHandlingView(onKeyDown: action))
    }
}

struct KeyEventHandlingView: NSViewRepresentable {
    let onKeyDown: (NSEvent) -> Bool
    
    func makeNSView(context: Context) -> NSView {
        let view = KeyHandlerNSView()
        view.onKeyDown = onKeyDown
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
}

class KeyHandlerNSView: NSView {
    var onKeyDown: ((NSEvent) -> Bool)?
    
    override var acceptsFirstResponder: Bool { true }
    
    override func keyDown(with event: NSEvent) {
        if let handler = onKeyDown, handler(event) {
            return
        }
        super.keyDown(with: event)
    }
}

struct ContentView: View {
    @StateObject private var clipboardManager = ClipboardManager.shared
    @State private var searchQuery = ""
    @State private var selectedIndex = 0
    @FocusState private var isSearchFocused: Bool
    private let windowOpacity: Double = 0.50

    var filteredHistory: [ClipboardEntry] {
        if searchQuery.isEmpty {
            return clipboardManager.clipboardHistory
        }
        return clipboardManager.clipboardHistory.filter {
            $0.content.localizedCaseInsensitiveContains(searchQuery)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            SearchBarView(searchQuery: $searchQuery, isSearchFocused: _isSearchFocused)
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color(nsColor: .separatorColor)),
                    alignment: .bottom
                )

            // Clipboard History
            if filteredHistory.isEmpty {
                EmptyStateView(hasSearchQuery: !searchQuery.isEmpty)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(filteredHistory.enumerated()), id: \.element.id) { index, entry in
                                VStack(spacing: 0) {
                                    ClipboardItemView(
                                        entry: entry,
                                        isSelected: index == selectedIndex,
                                        onCopy: { handleCopy(entry: entry) },
                                        onDelete: { clipboardManager.deleteEntry(entry) },
                                        onTogglePin: { clipboardManager.togglePin(entry) }
                                    )
                                    .id(entry.id)
                                    .onTapGesture {
                                        handleCopy(entry: entry)
                                    }

                                    if index < filteredHistory.count - 1 {
                                        Rectangle()
                                            .fill(Color(nsColor: .separatorColor))
                                            .frame(height: 0.5)
                                            .padding(.horizontal, 12)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 0)
                    }
                    .onChange(of: selectedIndex) { newValue in
                        if newValue < filteredHistory.count {
                            withAnimation {
                                proxy.scrollTo(filteredHistory[newValue].id, anchor: .center)
                            }
                        }
                    }
                }
            }

            // Footer
            if !clipboardManager.clipboardHistory.isEmpty {
                FooterView(onClearAll: {
                    clipboardManager.clearAll()
                })
            }
        }
        .frame(width: 326, height: 510)
        .background(.ultraThinMaterial)
        .onAppear {
            isSearchFocused = false
            selectedIndex = 0
        }
        .onChange(of: searchQuery) { _ in
            selectedIndex = 0
        }
        .onKeyDown { event in
            switch event.keyCode {
            case 125: // Down arrow
                if selectedIndex < filteredHistory.count - 1 {
                    selectedIndex += 1
                }
                return true
            case 126: // Up arrow
                if selectedIndex > 0 {
                    selectedIndex -= 1
                }
                return true
            case 36: // Return
                if !filteredHistory.isEmpty {
                    handleCopy(entry: filteredHistory[selectedIndex])
                }
                return true
            case 51: // Delete
                if !isSearchFocused && !filteredHistory.isEmpty {
                    clipboardManager.deleteEntry(filteredHistory[selectedIndex])
                    if selectedIndex >= filteredHistory.count {
                        selectedIndex = max(0, filteredHistory.count - 1)
                    }
                }
                return true
            default:
                return false
            }
        }
    }

    private func handleCopy(entry: ClipboardEntry) {
        // Close any visible popover (if hosted by AppDelegate) then hide our app to return focus
        if let appDelegate = NSApp.delegate as? AppDelegate, let popover = appDelegate.popover, popover.isShown {
            popover.performClose(nil)
            NSApp.hide(nil)
            appDelegate.restorePreviousApp()
        } else {
            NSApp.hide(nil)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            self.clipboardManager.copyEntry(entry, shouldPaste: true)
        }
    }
}
