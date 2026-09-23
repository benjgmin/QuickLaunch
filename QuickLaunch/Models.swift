import SwiftUI

struct AppInfo: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let path: String
    let icon: NSImage
    let isFile: Bool
    
    static func == (lhs: AppInfo, rhs: AppInfo) -> Bool {
        lhs.path == rhs.path
    }
}

struct ClipboardItem: Identifiable {
    let id = UUID()
    let content: String
    let timestamp: Date
    
    var preview: String {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count > 60 {
            return String(trimmed.prefix(60)) + "..."
        }
        return trimmed
    }
    
    var timeAgo: String {
        let seconds = Int(-timestamp.timeIntervalSinceNow)
        if seconds < 60 { return "Just now" }
        if seconds < 3600 { return "\(seconds / 60)m ago" }
        if seconds < 86400 { return "\(seconds / 3600)h ago" }
        return "\(seconds / 86400)d ago"
    }
}

enum SearchMode {
    case recent
    case apps
    case calculator
    case google
    case youtube
    case github
    case clipboard
    case emoji
    case system
    case define
}

struct SystemCommand: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let color: Color
    let action: () -> Void
}

struct EmojiItem: Identifiable {
    let id = UUID()
    let emoji: String
    let name: String
    let keywords: [String]
}
