import Foundation
import CryptoKit
import Security

/// Serial background persistence. Images are separate encrypted assets, never embedded in new history files.
final class StorageManager {
    static let shared = StorageManager()
    private let queue = DispatchQueue(label: "com.iclippy.storage", qos: .utility)
    private let directory: URL
    private let assets: URL
    private var encryptionKey: SymmetricKey?
    private var canSave = false
    private(set) var loadError: String?

    init(directory: URL? = nil, key: SymmetricKey? = nil) {
        self.directory = directory ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("iClippy")
        assets = self.directory.appendingPathComponent("Images")
        encryptionKey = key
    }

    private func key() throws -> SymmetricKey {
        if let encryptionKey { return encryptionKey }
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.iclippy.history", kSecAttrAccount as String: "encryption-key",
            kSecReturnData as String: true, kSecMatchLimit as String: kSecMatchLimitOne]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecSuccess, let data = item as? Data, data.count == 32 {
            let value = SymmetricKey(data: data); encryptionKey = value; return value
        }
        guard status == errSecItemNotFound else { throw StorageError.keyUnavailable }
        // Never generate a replacement key if encrypted history already exists.
        guard !FileManager.default.fileExists(atPath: historyURL.path) else { throw StorageError.keyUnavailable }
        let value = SymmetricKey(size: .bits256)
        var add = query
        add.removeValue(forKey: kSecReturnData as String)
        add.removeValue(forKey: kSecMatchLimit as String)
        add[kSecValueData as String] = value.withUnsafeBytes { Data($0) }
        add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        guard SecItemAdd(add as CFDictionary, nil) == errSecSuccess else { throw StorageError.keyUnavailable }
        encryptionKey = value
        return value
    }

    private var historyURL: URL { directory.appendingPathComponent("clipboard_history.encrypted") }
    private var legacyURL: URL { directory.appendingPathComponent("clipboard_history.json") }

    func loadHistory() -> [ClipboardEntry] {
        queue.sync {
            do {
                try FileManager.default.createDirectory(at: assets, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
                try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: directory.path)
                let cipherKey = try key()
                let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
                var entries: [ClipboardEntry] = []
                if FileManager.default.fileExists(atPath: historyURL.path) {
                    let data = try Data(contentsOf: historyURL)
                    entries = try decoder.decode([ClipboardEntry].self, from: decrypt(data, key: cipherKey))
                    for i in entries.indices {
                        if let name = entries[i].imageFileName {
                            guard name == entries[i].id.uuidString + ".encrypted" else { throw StorageError.invalidAsset }
                            entries[i].imageData = try decrypt(Data(contentsOf: assets.appendingPathComponent(name)), key: cipherKey)
                        }
                    }
                } else if FileManager.default.fileExists(atPath: legacyURL.path) {
                    entries = try decoder.decode([ClipboardEntry].self, from: Data(contentsOf: legacyURL))
                }
                canSave = true
                // Migration only removes the legacy file after the new store is durably written.
                try write(entries, key: cipherKey)
                return entries
            } catch {
                canSave = false
                loadError = "History could not be opened. Your existing files have been preserved. Check Keychain access and disk space, then restart iClippy."
                return []
            }
        }
    }

    func saveHistory(_ entries: [ClipboardEntry], completion: ((Bool) -> Void)? = nil) {
        queue.async {
            var success = false
            do {
                guard self.canSave else { throw StorageError.keyUnavailable }
                try self.write(entries, key: self.key())
                success = true
            } catch { NSLog("iClippy: history save failed; clipboard contents omitted") }
            let result = success
            DispatchQueue.main.async { completion?(result) }
        }
    }

    func flush() { queue.sync {} }

    private func write(_ entries: [ClipboardEntry], key: SymmetricKey) throws {
        var stored = entries
        var referenced = Set<String>()
        for i in stored.indices {
            if let image = stored[i].imageData {
                let name = stored[i].id.uuidString + ".encrypted"
                let url = assets.appendingPathComponent(name)
                if !FileManager.default.fileExists(atPath: url.path) { try secureWrite(encrypt(image, key: key), to: url) }
                stored[i].imageFileName = name
                stored[i].imageData = nil
                referenced.insert(name)
            }
        }
        let encoder = JSONEncoder(); encoder.dateEncodingStrategy = .iso8601
        try secureWrite(encrypt(encoder.encode(stored), key: key), to: historyURL)
        if FileManager.default.fileExists(atPath: legacyURL.path) { try FileManager.default.removeItem(at: legacyURL) }
        for file in try FileManager.default.contentsOfDirectory(at: assets, includingPropertiesForKeys: nil)
            where file.pathExtension == "encrypted" && !referenced.contains(file.lastPathComponent) {
            try FileManager.default.removeItem(at: file)
        }
    }

    private func secureWrite(_ data: Data, to url: URL) throws {
        try data.write(to: url, options: .atomic)
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
    }
    private func encrypt(_ data: Data, key: SymmetricKey) throws -> Data { try AES.GCM.seal(data, using: key).combined! }
    private func decrypt(_ data: Data, key: SymmetricKey) throws -> Data { try AES.GCM.open(AES.GCM.SealedBox(combined: data), using: key) }
    private enum StorageError: Error { case keyUnavailable, invalidAsset }
}
