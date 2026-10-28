import AppKit
import Combine

final class AppSettings: ObservableObject {
    static let shared = AppSettings()
    private let defaults: UserDefaults
    @Published var privateMode: Bool { didSet { defaults.set(privateMode, forKey: "privateMode") } }
    @Published var retentionDays: Int { didSet { defaults.set(retentionDays, forKey: "retentionDays") } }
    @Published var maxEntries: Int { didSet { defaults.set(maxEntries, forKey: "maxEntries") } }
    @Published var maxStorageMB: Int { didSet { defaults.set(maxStorageMB, forKey: "maxStorageMB") } }
    @Published var excludedApps: String { didSet { defaults.set(excludedApps, forKey: "excludedApps") } }
    @Published var recognizeImages: Bool { didSet { defaults.set(recognizeImages, forKey: "recognizeImages") } }
    @Published var shortcutCode: Int { didSet { defaults.set(shortcutCode, forKey: "shortcutCode") } }
    @Published var shortcutModifiers: UInt { didSet { defaults.set(Int(shortcutModifiers), forKey: "shortcutModifiers") } }
    @Published var shortcutLabel: String { didSet { defaults.set(shortcutLabel, forKey: "shortcutLabel") } }
    @Published var shortcutError = ""

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        privateMode = defaults.bool(forKey: "privateMode")
        retentionDays = defaults.object(forKey: "retentionDays") as? Int ?? 7
        maxEntries = defaults.object(forKey: "maxEntries") as? Int ?? 500
        maxStorageMB = defaults.object(forKey: "maxStorageMB") as? Int ?? 100
        excludedApps = defaults.string(forKey: "excludedApps") ?? "com.1password.1password\ncom.agilebits.onepassword7\ncom.bitwarden.desktop\ncom.apple.Passwords"
        recognizeImages = defaults.object(forKey: "recognizeImages") as? Bool ?? true
        shortcutCode = defaults.object(forKey: "shortcutCode") as? Int ?? 9
        shortcutModifiers = UInt(defaults.object(forKey: "shortcutModifiers") as? Int ?? Int(NSEvent.ModifierFlags([.command, .shift]).rawValue))
        shortcutLabel = defaults.string(forKey: "shortcutLabel") ?? "⌘⇧V"
    }

    func excludes(_ bundleID: String?) -> Bool {
        guard let bundleID else { return false }
        return excludedApps.components(separatedBy: .whitespacesAndNewlines)
            .contains { !$0.isEmpty && $0.caseInsensitiveCompare(bundleID) == .orderedSame }
    }
}

enum HistoryPolicy {
    static func sorted(_ entries: [ClipboardEntry]) -> [ClipboardEntry] {
        entries.sorted {
            let left = $0.isPinned || $0.isSnippet
            let right = $1.isPinned || $1.isSnippet
            return left != right ? left : $0.timestamp > $1.timestamp
        }
    }

    static func trim(_ entries: [ClipboardEntry], days: Int, count: Int, bytes: Int) -> [ClipboardEntry] {
        var result = sorted(entries.filter { !$0.isExpired(retentionDays: max(1, days)) })
        func size(_ e: ClipboardEntry) -> Int {
            e.content.utf8.count + (e.imageData?.count ?? 0) + (e.rtfData?.count ?? 0) + (e.recognizedText?.utf8.count ?? 0)
        }
        var total = result.reduce(0) { $0 + size($1) }
        while result.count > max(1, count) || total > max(1, bytes) {
            guard let index = result.lastIndex(where: { !$0.isPinned && !$0.isSnippet }) else { break }
            total -= size(result.remove(at: index))
        }
        return result
    }
}
