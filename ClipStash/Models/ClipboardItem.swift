import Foundation

struct ClipboardItem: Identifiable, Codable, Equatable {
    let id: UUID
    let content: String
    let copiedAt: Date
    let sourceApp: String?

    init(content: String, sourceApp: String? = nil) {
        self.id = UUID()
        self.content = content
        self.copiedAt = Date()
        self.sourceApp = sourceApp
    }

    var preview: String {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        let firstLine = trimmed.components(separatedBy: .newlines).first ?? trimmed
        if firstLine.count > 80 {
            return String(firstLine.prefix(80)) + "..."
        }
        return firstLine
    }

    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: copiedAt, relativeTo: Date())
    }

    func matches(query: String) -> Bool {
        guard !query.isEmpty else { return true }
        return content.localizedCaseInsensitiveContains(query)
    }
}
