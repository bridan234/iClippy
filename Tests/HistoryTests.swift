import CryptoKit
import AppKit

final class HistoryTests {
    func testLegacyEntriesDecodeWithoutNewMetadata() throws {
        let json = """
        [{"id":"7E605147-2237-4D8F-85DA-090A14378103","content":"hello","type":"text","timestamp":"2026-01-01T00:00:00Z","isPinned":false}]
        """
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
        let entries = try decoder.decode([ClipboardEntry].self, from: Data(json.utf8))
        XCTAssertEqual(entries.first?.content, "hello")
        XCTAssertNil(entries.first?.snippetName)
        XCTAssertNil(entries.first?.recognizedText)
    }

    func testPruningPreservesPinsAndSnippetsAndSortsNewCaptures() {
        var pin = ClipboardEntry.fromText("pin"); pin.isPinned = true; pin.timestamp = .distantPast
        var snippet = ClipboardEntry.fromText("snippet"); snippet.snippetName = "Greeting"; snippet.timestamp = .distantPast
        var expired = ClipboardEntry.fromText("expired"); expired.timestamp = .distantPast
        let fresh = ClipboardEntry.fromText("fresh")
        let entries = HistoryPolicy.trim([fresh, pin, expired, snippet], days: 7, count: 3, bytes: 1000)
        XCTAssertEqual(entries.count, 3)
        XCTAssertTrue(entries.prefix(2).allSatisfy { $0.isPinned || $0.isSnippet })
        XCTAssertEqual(entries.last?.id, fresh.id)
        XCTAssertEqual(HistoryPolicy.trim(entries, days: 7, count: 1, bytes: 1).count, 2)
    }

    func testSearchIncludesSourceSnippetAndRecognizedText() {
        var image = ClipboardEntry.fromImage(Data([1]))
        image.recognizedText = "Invoice October"; image.sourceAppName = "Preview"
        image.sourceBundleID = "com.apple.Preview"; image.snippetName = "Receipt"
        for term in ["invoice", "preview", "com.apple.preview", "receipt"] {
            XCTAssertTrue(image.searchableText.localizedCaseInsensitiveContains(term))
        }
    }

    func testEncryptedLegacyMigrationAndAssetCleanup() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let key = SymmetricKey(size: .bits256)
        let image = ClipboardEntry.fromImage(Data("test image".utf8))
        let secret = ClipboardEntry.fromText("sensitive fixture")
        let encoder = JSONEncoder(); encoder.dateEncodingStrategy = .iso8601
        let legacy = directory.appendingPathComponent("clipboard_history.json")
        try encoder.encode([secret, image]).write(to: legacy)
        let storage = StorageManager(directory: directory, key: key)
        XCTAssertEqual(storage.loadHistory().count, 2)
        XCTAssertFalse(FileManager.default.fileExists(atPath: legacy.path))
        let encrypted = try Data(contentsOf: directory.appendingPathComponent("clipboard_history.encrypted"))
        XCTAssertNil(encrypted.range(of: Data(secret.content.utf8)))
        let second = StorageManager(directory: directory, key: key)
        let loaded = second.loadHistory()
        XCTAssertEqual(loaded.first?.content, secret.content)
        XCTAssertEqual(loaded.last?.imageData, image.imageData)
        storage.saveHistory([secret]); storage.flush()
        XCTAssertTrue(try FileManager.default.contentsOfDirectory(atPath: directory.appendingPathComponent("Images").path).isEmpty)
    }

    func testWrongKeyDoesNotOverwriteHistory() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let good = StorageManager(directory: directory, key: SymmetricKey(size: .bits256))
        _ = good.loadHistory(); good.saveHistory([.fromText("preserve me")]); good.flush()
        let url = directory.appendingPathComponent("clipboard_history.encrypted")
        let original = try Data(contentsOf: url)
        let bad = StorageManager(directory: directory, key: SymmetricKey(size: .bits256))
        XCTAssertTrue(bad.loadHistory().isEmpty); XCTAssertNotNil(bad.loadError)
        bad.saveHistory([.fromText("replacement")]); bad.flush()
        XCTAssertEqual(try Data(contentsOf: url), original)
    }

    func testCopyPreservesImageAndRTFAndSupportsPlainText() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let board = NSPasteboard.withUniqueName()
        defer { board.releaseGlobally() }
        let storage = StorageManager(directory: directory, key: SymmetricKey(size: .bits256))
        let manager = ClipboardManager(pasteboard: board, storage: storage, monitoring: false)
        let text = NSAttributedString(string: "formatted text")
        let rtf = try text.data(from: NSRange(location: 0, length: text.length), documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf])
        let entry = ClipboardEntry.fromText(text.string, hasRTF: true, rtfData: rtf)
        manager.copyToClipboard(entry)
        XCTAssertEqual(board.data(forType: .rtf), rtf)
        manager.copyToClipboard(entry, plainText: true)
        XCTAssertEqual(board.string(forType: .string), text.string)
        XCTAssertNil(board.data(forType: .rtf))
        let image = NSImage(size: NSSize(width: 10, height: 10))
        image.lockFocus(); NSColor.red.setFill(); NSRect(x: 0, y: 0, width: 10, height: 10).fill(); image.unlockFocus()
        let imageEntry = ClipboardEntry.fromImage(try XCTUnwrap(image.tiffRepresentation))
        manager.copyToClipboard(imageEntry)
        XCTAssertNotNil(board.data(forType: .tiff))
        XCTAssertNotEqual(board.string(forType: .string), "Image")
        storage.flush()
    }
    func testPrivacyAndOwnWritesDoNotLoseLaterExternalCopy() throws {
        let suite = "iClippyTests." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let settings = AppSettings(defaults: defaults)
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let board = NSPasteboard.withUniqueName(); defer { board.releaseGlobally() }
        let storage = StorageManager(directory: directory, key: SymmetricKey(size: .bits256))
        let manager = ClipboardManager(pasteboard: board, storage: storage, settings: settings, monitoring: false)
        board.clearContents(); board.setString("secret", forType: .string)
        board.setData(Data(), forType: NSPasteboard.PasteboardType("org.nspasteboard.ConcealedType"))
        manager.checkClipboard(); XCTAssertTrue(manager.entries.isEmpty)
        settings.privateMode = true
        board.clearContents(); board.setString("private", forType: .string)
        manager.checkClipboard(); XCTAssertTrue(manager.entries.isEmpty)
        settings.privateMode = false
        manager.checkClipboard(); XCTAssertTrue(manager.entries.isEmpty)
        manager.copyToClipboard(.fromText("our write"))
        board.clearContents(); board.setString("new external copy", forType: .string)
        manager.checkClipboard()
        XCTAssertEqual(manager.entries.first?.content, "new external copy")
        settings.excludedApps = "com.example.Secret\ncom.example.Another"
        XCTAssertTrue(settings.excludes("com.example.Secret"))
        XCTAssertFalse(settings.excludes("com.example.SecretExtra"))
        storage.flush()
    }

    func testOnDeviceImageTextRecognition() throws {
        let image = NSImage(size: NSSize(width: 1000, height: 200))
        image.lockFocus()
        NSColor.white.setFill(); NSRect(x: 0, y: 0, width: 1000, height: 200).fill()
        ("INVOICE 4827" as NSString).draw(at: NSPoint(x: 40, y: 70), withAttributes: [
            .font: NSFont.systemFont(ofSize: 64), .foregroundColor: NSColor.black])
        image.unlockFocus()
        let result = ImageTextRecognizer.recognize(try XCTUnwrap(image.tiffRepresentation))
        XCTAssertTrue(result?.contains("4827") == true)
        XCTAssertTrue(result?.localizedCaseInsensitiveContains("invoice") == true)
    }

}

private func XCTAssertTrue(_ value: Bool, file: StaticString = #file, line: UInt = #line) { precondition(value, "Expected true", file: file, line: line) }
private func XCTAssertFalse(_ value: Bool, file: StaticString = #file, line: UInt = #line) { precondition(!value, "Expected false", file: file, line: line) }
private func XCTAssertNil<T>(_ value: T?, file: StaticString = #file, line: UInt = #line) { precondition(value == nil, "Expected nil", file: file, line: line) }
private func XCTAssertNotNil<T>(_ value: T?, file: StaticString = #file, line: UInt = #line) { precondition(value != nil, "Expected a value", file: file, line: line) }
private func XCTAssertEqual<T: Equatable>(_ lhs: T, _ rhs: T, file: StaticString = #file, line: UInt = #line) { precondition(lhs == rhs, "Values differ", file: file, line: line) }
private func XCTAssertNotEqual<T: Equatable>(_ lhs: T, _ rhs: T, file: StaticString = #file, line: UInt = #line) { precondition(lhs != rhs, "Values must differ", file: file, line: line) }
private func XCTUnwrap<T>(_ value: T?) throws -> T { guard let value else { throw NSError(domain: "iClippyTests", code: 1) }; return value }

@main
struct RegressionRunner {
    static func main() throws {
        _ = NSApplication.shared
        let suite = HistoryTests()
        let tests: [(String, () throws -> Void)] = [
            ("legacy metadata decoding", suite.testLegacyEntriesDecodeWithoutNewMetadata),
            ("retention, limits, and pin ordering", suite.testPruningPreservesPinsAndSnippetsAndSortsNewCaptures),
            ("search metadata", suite.testSearchIncludesSourceSnippetAndRecognizedText),
            ("encrypted migration and asset cleanup", suite.testEncryptedLegacyMigrationAndAssetCleanup),
            ("unreadable history preservation", suite.testWrongKeyDoesNotOverwriteHistory),
            ("image, rich-text, and plain-text copying", suite.testCopyPreservesImageAndRTFAndSupportsPlainText),
            ("privacy and clipboard write race", suite.testPrivacyAndOwnWritesDoNotLoseLaterExternalCopy),
            ("on-device image text recognition", suite.testOnDeviceImageTextRecognition)
        ]
        for (name, test) in tests { try test(); print("PASS: " + name) }
        print("All \(tests.count) regression checks passed.")
    }
}
