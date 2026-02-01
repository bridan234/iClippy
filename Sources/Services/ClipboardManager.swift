import AppKit
import Foundation

class ClipboardManager: ObservableObject {
    static let shared = ClipboardManager()

    @Published var clipboardHistory: [ClipboardEntry] = []
    private var lastChangeCount: Int = 0
    private var timer: Timer?
    private let pasteboard = NSPasteboard.general
    private let storageManager = StorageManager.shared
    private var isInternalChange = false

    private init() {
        loadHistory()
        cleanupExpiredEntries()
    }

    func startMonitoring() {
        lastChangeCount = pasteboard.changeCount
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    private func checkClipboard() {
        let currentCount = pasteboard.changeCount

        // Skip if it's our own change
        if isInternalChange {
            lastChangeCount = currentCount
            isInternalChange = false
            return
        }

        if currentCount != lastChangeCount {
            lastChangeCount = currentCount
            captureClipboardContent()
        }
    }

    private func captureClipboardContent() {
        // Check for image first
        if let image = pasteboard.data(forType: .png) ?? pasteboard.data(forType: .tiff) {
            let content = "Image"
            addEntry(content: content, type: .image, imageData: image)
            return
        }

        // Check for RTF
        if let rtfData = pasteboard.data(forType: .rtf),
           let attributedString = NSAttributedString(rtf: rtfData, documentAttributes: nil),
           !attributedString.string.isEmpty {
            addEntry(content: attributedString.string, type: .richText, rtfData: rtfData)
            return
        }

        // Check for plain text
        if let text = pasteboard.string(forType: .string), !text.isEmpty {
            let type = detectType(for: text)
            addEntry(content: text, type: type)
        }
    }

    private func detectType(for text: String) -> ClipboardEntryType {
        // Simple code detection heuristics
        let codeIndicators = ["import ", "const ", "let ", "var ", "function ", "class ", "def ", "public ", "private ", "{", "}", "=>", "async ", "await "]

        for indicator in codeIndicators {
            if text.contains(indicator) {
                return .code
            }
        }

        return .text
    }

    private func addEntry(content: String, type: ClipboardEntryType, imageData: Data? = nil, rtfData: Data? = nil) {
        // Don't add duplicate consecutive entries
        if let lastEntry = clipboardHistory.first,
           lastEntry.content == content,
           lastEntry.type == type {
            return
        }

        let entry = ClipboardEntry(
            content: content,
            type: type,
            imageData: imageData,
            rtfData: rtfData
        )

        DispatchQueue.main.async {
            self.clipboardHistory.insert(entry, at: 0)
            self.saveHistory()
            self.cleanupExpiredEntries()
        }
    }

    func copyEntry(_ entry: ClipboardEntry, shouldPaste: Bool = false) {
        isInternalChange = true
        pasteboard.clearContents()

        // Restore the original content type
        if let imageData = entry.imageData {
            pasteboard.setData(imageData, forType: .png)
        } else if let rtfData = entry.rtfData {
            pasteboard.setData(rtfData, forType: .rtf)
        } else {
            pasteboard.setString(entry.content, forType: .string)
        }

        if shouldPaste {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                self.simulatePaste()
            }
        }
    }

    private func simulatePaste() {
        // Simulate Command+V keypress
        let source = CGEventSource(stateID: .combinedSessionState)

        // The 'v' key virtual key code is 0x09
        let vKeyCode: CGKeyCode = 0x09

        // Create key down event with Command modifier
        guard let keyDownEvent = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: true) else {
            print("Failed to create key down event")
            return
        }
        keyDownEvent.flags = .maskCommand

        // Create key up event with Command modifier
        guard let keyUpEvent = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: false) else {
            print("Failed to create key up event")
            return
        }
        keyUpEvent.flags = .maskCommand

        // Post both events
        keyDownEvent.post(tap: .cghidEventTap)

        // Small delay between key down and key up for proper key event
        usleep(20000) // 20ms delay

        keyUpEvent.post(tap: .cghidEventTap)
    }

    func deleteEntry(_ entry: ClipboardEntry) {
        clipboardHistory.removeAll { $0.id == entry.id }
        saveHistory()
    }

    func clearAll() {
        clipboardHistory.removeAll()
        saveHistory()
    }

    func togglePin(_ entry: ClipboardEntry) {
        if let index = clipboardHistory.firstIndex(where: { $0.id == entry.id }) {
            clipboardHistory[index].isPinned.toggle()

            // Move pinned items to top
            if clipboardHistory[index].isPinned {
                let pinnedEntry = clipboardHistory.remove(at: index)
                // Find position after last pinned item
                let insertIndex = clipboardHistory.firstIndex(where: { !$0.isPinned }) ?? 0
                clipboardHistory.insert(pinnedEntry, at: insertIndex)
            }

            saveHistory()
        }
    }

    private func cleanupExpiredEntries() {
        let beforeCount = clipboardHistory.count
        clipboardHistory.removeAll { $0.isExpired() }

        if clipboardHistory.count != beforeCount {
            saveHistory()
        }
    }

    private func saveHistory() {
        storageManager.save(clipboardHistory)
    }

    private func loadHistory() {
        clipboardHistory = storageManager.load()
        cleanupExpiredEntries()
    }
}
