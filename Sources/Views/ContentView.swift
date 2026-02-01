import SwiftUI
import AppKit

struct ContentView: View {
    @EnvironmentObject var clipboardManager: ClipboardManager
    @Environment(\.pasteHandler) var pasteHandler
    @State private var searchText = ""
    @State private var hoveredEntry: UUID?
    @State private var selectedIndex: Int = 0

    var filteredEntries: [ClipboardEntry] {
        if searchText.isEmpty {
            return clipboardManager.entries
        }
        return clipboardManager.entries.filter { entry in
            entry.content.localizedCaseInsensitiveContains(searchText)
        }
    }

    var selectedEntry: ClipboardEntry? {
        guard !filteredEntries.isEmpty, selectedIndex >= 0, selectedIndex < filteredEntries.count else {
            return nil
        }
        return filteredEntries[selectedIndex]
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            SearchBarView(text: $searchText, onEscape: {
                closePopover()
            })

            Divider()

            // Clipboard history list
            if filteredEntries.isEmpty {
                EmptyStateView(isSearching: !searchText.isEmpty)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(filteredEntries.enumerated()), id: \.element.id) { index, entry in
                            ClipboardItemView(
                                entry: entry,
                                isHovered: hoveredEntry == entry.id,
                                isSelected: selectedIndex == index,
                                onPaste: {
                                    pasteHandler(entry)
                                },
                                onPin: {
                                    clipboardManager.togglePin(entry)
                                },
                                onDelete: {
                                    clipboardManager.deleteEntry(entry)
                                    // Adjust selection if needed
                                    if selectedIndex >= filteredEntries.count - 1 {
                                        selectedIndex = max(0, filteredEntries.count - 2)
                                    }
                                }
                            )
                            .onHover { isHovered in
                                hoveredEntry = isHovered ? entry.id : nil
                                if isHovered {
                                    selectedIndex = index
                                }
                            }
                            .id(entry.id)

                            if entry.id != filteredEntries.last?.id {
                                Divider()
                            }
                        }
                    }
                }
            }

            // Footer
            if !clipboardManager.entries.isEmpty {
                Divider()
                FooterView(onClearAll: {
                    clipboardManager.clearUnpinned()
                    selectedIndex = 0
                })
            }
        }
        .frame(width: 326, height: 510)
        .background(VisualEffectView(material: .popover, blendingMode: .behindWindow))
        .onAppear {
            setupKeyboardMonitoring()
        }
        .onChange(of: searchText) { _ in
            // Reset selection when search changes
            selectedIndex = 0
        }
    }

    // MARK: - Keyboard Handling

    private func setupKeyboardMonitoring() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            return handleKeyDown(event: event)
        }
    }

    private func handleKeyDown(event: NSEvent) -> NSEvent? {
        guard !filteredEntries.isEmpty else { return event }

        switch event.keyCode {
        case 126: // Up arrow
            moveSelection(by: -1)
            return nil

        case 125: // Down arrow
            moveSelection(by: 1)
            return nil

        case 36: // Enter/Return
            if let entry = selectedEntry {
                pasteHandler(entry)
            }
            return nil

        case 53: // Escape
            closePopover()
            return nil

        default:
            return event
        }
    }

    private func moveSelection(by offset: Int) {
        let newIndex = selectedIndex + offset
        selectedIndex = max(0, min(newIndex, filteredEntries.count - 1))
    }

    private func closePopover() {
        NSApp.sendAction(#selector(AppDelegate.togglePopover), to: nil, from: nil)
    }
}

