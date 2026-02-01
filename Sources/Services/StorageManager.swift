import Foundation

class StorageManager {
    static let shared = StorageManager()

    private let fileURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDirectory = appSupport.appendingPathComponent("iClippy", isDirectory: true)

        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(at: appDirectory, withIntermediateDirectories: true)

        fileURL = appDirectory.appendingPathComponent("clipboard_history.json")
    }

    func save(_ entries: [ClipboardEntry]) {
        do {
            let data = try encoder.encode(entries)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Failed to save clipboard history: \(error)")
        }
    }

    func load() -> [ClipboardEntry] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let entries = try decoder.decode([ClipboardEntry].self, from: data)
            return entries
        } catch {
            print("Failed to load clipboard history: \(error)")
            return []
        }
    }
}
