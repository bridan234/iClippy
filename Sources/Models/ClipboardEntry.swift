import Foundation
import SwiftUI

/// Represents the type of content stored in a clipboard entry
enum ContentType: String, Codable {
    case text
    case code
    case richText
    case image

    /// Detects the content type based on clipboard content and metadata
    static func detect(from string: String?, hasRTF: Bool = false, hasImage: Bool = false) -> ContentType {
        if hasImage {
            return .image
        }

        if hasRTF {
            return .richText
        }

        guard let content = string, !content.isEmpty else {
            return .text
        }

        // Check for code indicators
        let codeKeywords = [
            // Common programming keywords
            "func ", "function ", "def ", "class ", "struct ", "enum ", "interface ",
            "import ", "export ", "const ", "let ", "var ", "public ", "private ",
            "return ", "if (", "while (", "for (", "switch ", "case ",
            // Common syntax patterns
            "=>", "->", "<?", "?>", "||", "&&", "===", "!==",
            // Brackets and braces patterns common in code
        ]

        let codeSyntaxPatterns = [
            #"\{[\s\S]*\}"#,  // Curly braces with content
            #"\(.*\)\s*=>"#,  // Arrow functions
            #"^\s*(public|private|protected)\s"#,  // Access modifiers
            #"^\s*(const|let|var)\s+\w+\s*="#,  // Variable declarations
            #"^\s*import\s+.*from"#,  // ES6 imports
        ]

        // Check for keywords
        for keyword in codeKeywords {
            if content.contains(keyword) {
                return .code
            }
        }

        // Check for syntax patterns using regex
        for pattern in codeSyntaxPatterns {
            if content.range(of: pattern, options: .regularExpression) != nil {
                return .code
            }
        }

        // Check for multiple consecutive lines with indentation (code-like structure)
        let lines = content.components(separatedBy: .newlines)
        if lines.count > 2 {
            let indentedLines = lines.filter { $0.hasPrefix("    ") || $0.hasPrefix("\t") }
            if indentedLines.count >= 2 {
                return .code
            }
        }

        return .text
    }

    /// Returns a user-friendly display name for the content type
    var displayName: String {
        switch self {
        case .text: return "Text"
        case .code: return "Code"
        case .richText: return "Rich"
        case .image: return "Image"
        }
    }

    /// Returns a color associated with the content type for UI display
    var badgeColor: Color {
        switch self {
        case .text: return .blue
        case .code: return .green
        case .richText: return .purple
        case .image: return .orange
        }
    }
}

/// Represents a single entry in the clipboard history
struct ClipboardEntry: Identifiable, Codable, Equatable {
    let id: UUID
    var content: String
    var type: ContentType
    var timestamp: Date
    var isPinned: Bool
    var imageData: Data?
    var rtfData: Data?

    init(
        id: UUID = UUID(),
        content: String,
        type: ContentType,
        timestamp: Date = Date(),
        isPinned: Bool = false,
        imageData: Data? = nil,
        rtfData: Data? = nil
    ) {
        self.id = id
        self.content = content
        self.type = type
        self.timestamp = timestamp
        self.isPinned = isPinned
        self.imageData = imageData
        self.rtfData = rtfData
    }

    // MARK: - Computed Properties

    /// Returns a preview of the content suitable for display in a list
    var preview: String {
        if type == .image {
            return "Image"
        }

        // Remove extra whitespace and newlines for preview
        let cleaned = content
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        // Truncate if too long
        let maxLength = 100
        if cleaned.count > maxLength {
            return String(cleaned.prefix(maxLength)) + "..."
        }

        return cleaned.isEmpty ? "(Empty)" : cleaned
    }

    /// Returns a formatted relative timestamp (e.g., "2 minutes ago")
    var relativeTimestamp: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }

    /// Returns true if this entry has expired based on the given retention days
    func isExpired(retentionDays: Int = 3) -> Bool {
        // Pinned entries never expire
        if isPinned {
            return false
        }

        let expirationDate = Calendar.current.date(byAdding: .day, value: retentionDays, to: timestamp)
        return Date() > (expirationDate ?? Date())
    }

    // MARK: - Equatable

    static func == (lhs: ClipboardEntry, rhs: ClipboardEntry) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Convenience Initializers

extension ClipboardEntry {
    /// Creates a clipboard entry from text content
    static func fromText(_ text: String, hasRTF: Bool = false, rtfData: Data? = nil) -> ClipboardEntry {
        let type = ContentType.detect(from: text, hasRTF: hasRTF)
        return ClipboardEntry(
            content: text,
            type: type,
            rtfData: rtfData
        )
    }

    /// Creates a clipboard entry from image data
    static func fromImage(_ imageData: Data) -> ClipboardEntry {
        return ClipboardEntry(
            content: "Image",
            type: .image,
            imageData: imageData
        )
    }
}
