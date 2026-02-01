import Foundation
import AppKit

class ClipboardManager: ObservableObject {
    @Published var entries: [ClipboardEntry] = []

    private var lastChangeCount: Int = 0
    private var timer: Timer?
    private let pasteboard = NSPasteboard.general

    /// Flag to prevent capturing our own internal clipboard changes
    private var isInternalChange = false

    init() {
        // Load history from disk
        entries = StorageManager.shared.loadHistory()
        lastChangeCount = pasteboard.changeCount

        // Start monitoring clipboard
        startMonitoring()
    }

    // MARK: - Monitoring

    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    private func checkClipboard() {
        let currentChangeCount = pasteboard.changeCount

        guard currentChangeCount != lastChangeCount else { return }
        lastChangeCount = currentChangeCount

        // Skip if this is an internal change (we wrote to clipboard)
        if isInternalChange {
            isInternalChange = false
            return
        }

        captureClipboard()
    }

    // MARK: - Capture

    private func captureClipboard() {
        var capturedEntry: ClipboardEntry?

        // Priority 1: Try to capture image data
        if let imageData = pasteboard.data(forType: .tiff) ?? pasteboard.data(forType: .png) {
            capturedEntry = ClipboardEntry.fromImage(imageData)
        }
        // Priority 2: Try to capture rich text
        else if let rtfData = pasteboard.data(forType: .rtf),
                let text = pasteboard.string(forType: .string), !text.isEmpty {
            capturedEntry = ClipboardEntry.fromText(text, hasRTF: true, rtfData: rtfData)
        }
        // Priority 3: Try to capture plain text
        else if let text = pasteboard.string(forType: .string), !text.isEmpty {
            capturedEntry = ClipboardEntry.fromText(text)
        }

        if let entry = capturedEntry {
            addEntry(entry)
        }
    }

    private func addEntry(_ entry: ClipboardEntry) {
        // Don't add duplicates - check if the same content is already at the top
        if let first = entries.first {
            // For images, compare image data; for text, compare content
            if entry.type == .image {
                if first.type == .image && first.imageData == entry.imageData {
                    return
                }
            } else {
                if first.content == entry.content {
                    return
                }
            }
        }

        // Insert at top of history
        entries.insert(entry, at: 0)

        // Persist to disk
        StorageManager.shared.saveHistory(entries)

        print("📋 Captured new clipboard entry: \(entry.type.displayName) - \(entry.preview)")
    }

    // MARK: - Paste

    /// Copies an entry back to the system clipboard for pasting
    func copyToClipboard(_ entry: ClipboardEntry) {
        isInternalChange = true

        pasteboard.clearContents()

        if entry.type == .image, let imageData = entry.imageData {
            // Write image data
            pasteboard.setData(imageData, forType: .tiff)
        } else if let rtfData = entry.rtfData {
            // Write both RTF and plain text
            pasteboard.setData(rtfData, forType: .rtf)
            pasteboard.setString(entry.content, forType: .string)
        } else {
            // Write plain text
            pasteboard.setString(entry.content, forType: .string)
        }

        print("📋 Copied entry to clipboard: \(entry.preview)")
    }

    // MARK: - Management

    /// Toggles the pin state of an entry
    func togglePin(_ entry: ClipboardEntry) {
        guard let index = entries.firstIndex(where: { $0.id == entry.id }) else { return }

        entries[index].isPinned.toggle()

        // Re-sort to move pinned items to the top
        sortEntries()

        // Persist changes
        StorageManager.shared.saveHistory(entries)
    }

    /// Deletes a single entry from history
    func deleteEntry(_ entry: ClipboardEntry) {
        entries.removeAll { $0.id == entry.id }
        StorageManager.shared.saveHistory(entries)
    }

    /// Clears all unpinned entries
    func clearUnpinned() {
        entries.removeAll { !$0.isPinned }
        StorageManager.shared.saveHistory(entries)
    }

    /// Sorts entries with pinned items at the top, then by timestamp
    private func sortEntries() {
        entries.sort { lhs, rhs in
            if lhs.isPinned != rhs.isPinned {
                return lhs.isPinned
            }
            return lhs.timestamp > rhs.timestamp
        }
    }
}
