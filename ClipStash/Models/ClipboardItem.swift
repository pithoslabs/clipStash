import Foundation

struct ClipboardRepresentation: Codable, Equatable {
    let type: String
    let data: Data
}

struct ClipboardItem: Identifiable, Codable, Equatable {
    let id: UUID
    let content: String
    let copiedAt: Date
    let sourceApp: String?
    let isStarred: Bool
    let representations: [ClipboardRepresentation]

    init(
        id: UUID = UUID(),
        content: String,
        copiedAt: Date = Date(),
        sourceApp: String? = nil,
        isStarred: Bool = false,
        representations: [ClipboardRepresentation] = []
    ) {
        self.id = id
        self.content = content
        self.copiedAt = copiedAt
        self.sourceApp = sourceApp
        self.isStarred = isStarred
        self.representations = representations
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case content
        case copiedAt
        case sourceApp
        case isStarred
        case representations
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        content = try container.decode(String.self, forKey: .content)
        copiedAt = try container.decode(Date.self, forKey: .copiedAt)
        sourceApp = try container.decodeIfPresent(String.self, forKey: .sourceApp)
        isStarred = try container.decodeIfPresent(Bool.self, forKey: .isStarred) ?? false
        representations = try container.decodeIfPresent([ClipboardRepresentation].self, forKey: .representations) ?? []
    }

    func withStarred(_ isStarred: Bool) -> ClipboardItem {
        ClipboardItem(
            id: id,
            content: content,
            copiedAt: copiedAt,
            sourceApp: sourceApp,
            isStarred: isStarred,
            representations: representations
        )
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
