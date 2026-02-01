import Foundation

/// Manages persistent storage of clipboard history to disk
class StorageManager {
    // MARK: - Properties

    /// Shared singleton instance
    static let shared = StorageManager()

    /// URL to the application support directory
    private let appSupportDirectory: URL

    /// URL to the clipboard history JSON file
    private let historyFileURL: URL

    /// Name of the history file
    private let historyFileName = "clipboard_history.json"

    // MARK: - Initialization

    private init() {
        // Get the Application Support directory
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        self.appSupportDirectory = appSupport.appendingPathComponent("iClippy", isDirectory: true)
        self.historyFileURL = appSupportDirectory.appendingPathComponent(historyFileName)

        // Create the directory if it doesn't exist
        createDirectoryIfNeeded()
    }

    // MARK: - Directory Management

    /// Creates the application support directory if it doesn't exist
    private func createDirectoryIfNeeded() {
        let fileManager = FileManager.default

        if !fileManager.fileExists(atPath: appSupportDirectory.path) {
            do {
                try fileManager.createDirectory(
                    at: appSupportDirectory,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
                print("✅ Created application support directory at: \(appSupportDirectory.path)")
            } catch {
                print("❌ Failed to create application support directory: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Save Operations

    /// Saves clipboard history to disk
    /// - Parameter entries: Array of ClipboardEntry objects to save
    /// - Returns: True if save was successful, false otherwise
    @discardableResult
    func saveHistory(_ entries: [ClipboardEntry]) -> Bool {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

            let data = try encoder.encode(entries)
            try data.write(to: historyFileURL, options: .atomic)

            print("✅ Saved \(entries.count) clipboard entries to disk")
            return true
        } catch {
            print("❌ Failed to save clipboard history: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Load Operations

    /// Loads clipboard history from disk
    /// - Returns: Array of ClipboardEntry objects, or empty array if loading fails
    func loadHistory() -> [ClipboardEntry] {
        // Check if file exists
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: historyFileURL.path) else {
            print("ℹ️ No existing history file found, starting fresh")
            return []
        }

        do {
            let data = try Data(contentsOf: historyFileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            let entries = try decoder.decode([ClipboardEntry].self, from: data)
            print("✅ Loaded \(entries.count) clipboard entries from disk")

            // Filter out expired entries
            let validEntries = entries.filter { !$0.isExpired() }
            let expiredCount = entries.count - validEntries.count

            if expiredCount > 0 {
                print("🗑️ Removed \(expiredCount) expired entries")
                // Save the filtered list back to disk
                saveHistory(validEntries)
            }

            return validEntries
        } catch {
            print("❌ Failed to load clipboard history: \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - Delete Operations

    /// Deletes all clipboard history from disk
    /// - Returns: True if deletion was successful, false otherwise
    @discardableResult
    func deleteHistory() -> Bool {
        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: historyFileURL.path) else {
            print("ℹ️ No history file to delete")
            return true
        }

        do {
            try fileManager.removeItem(at: historyFileURL)
            print("✅ Deleted clipboard history file")
            return true
        } catch {
            print("❌ Failed to delete clipboard history: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Utility Methods

    /// Returns the size of the history file in bytes
    var historyFileSize: Int64? {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: historyFileURL.path) else {
            return nil
        }

        do {
            let attributes = try fileManager.attributesOfItem(atPath: historyFileURL.path)
            return attributes[.size] as? Int64
        } catch {
            print("❌ Failed to get file size: \(error.localizedDescription)")
            return nil
        }
    }

    /// Returns a human-readable file size string
    var historyFileSizeFormatted: String {
        guard let size = historyFileSize else {
            return "0 KB"
        }

        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }

    /// Returns the path to the history file
    var historyFilePath: String {
        return historyFileURL.path
    }
}
