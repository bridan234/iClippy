import Foundation
import AppKit

enum ClipboardEntryType: String, Codable {
    case text
    case code
    case image
    case richText
}

struct ClipboardEntry: Identifiable, Codable, Equatable {
    let id: UUID
    var content: String
    var type: ClipboardEntryType
    var timestamp: Date
    var isPinned: Bool
    var imageData: Data?
    var rtfData: Data?

    init(id: UUID = UUID(), content: String, type: ClipboardEntryType, timestamp: Date = Date(), isPinned: Bool = false, imageData: Data? = nil, rtfData: Data? = nil) {
        self.id = id
        self.content = content
        self.type = type
        self.timestamp = timestamp
        self.isPinned = isPinned
        self.imageData = imageData
        self.rtfData = rtfData
    }

    static func == (lhs: ClipboardEntry, rhs: ClipboardEntry) -> Bool {
        lhs.id == rhs.id
    }

    func isExpired() -> Bool {
        if isPinned { return false }
        let fortyEightHoursAgo = Date().addingTimeInterval(-48 * 60 * 60)
        return timestamp < fortyEightHoursAgo
    }

    func formattedTime() -> String {
        let now = Date()
        let diff = now.timeIntervalSince(timestamp)
        let minutes = Int(diff / 60)
        let hours = Int(diff / 3600)
        let days = Int(diff / 86400)

        if minutes < 1 { return "Just now" }
        if minutes < 60 { return "\(minutes)m ago" }
        if hours < 24 { return "\(hours)h ago" }
        return "\(days)d ago"
    }
}
