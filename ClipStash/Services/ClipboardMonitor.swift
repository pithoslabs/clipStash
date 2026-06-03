import AppKit
import Combine

final class ClipboardMonitor: ObservableObject {
    static let shared = ClipboardMonitor()

    private var timer: Timer?
    private var lastChangeCount: Int = 0
    private let pasteboard = NSPasteboard.general

    /// Maximum content size to store (1MB)
    private let maxContentSize = 1_000_000
    private let maxRepresentationBytes = 2_000_000

    private let textPasteboardTypes: Set<String> = [
        "public.utf8-plain-text",
        "public.utf16-plain-text",
        "NSStringPboardType",
        "public.rtf",
        "NeXT Rich Text Format v1.0 pasteboard type",
        "com.apple.flat-rtfd",
        "public.html",
        "Apple HTML pasteboard type"
    ]

    /// Track frontmost app to attribute clipboard content correctly
    /// We store the app that was frontmost *before* detecting a change,
    /// since the actual copy happened before our polling detected it
    private var lastKnownFrontmostApp: String?

    private init() {
        lastChangeCount = pasteboard.changeCount
        lastKnownFrontmostApp = NSWorkspace.shared.frontmostApplication?.localizedName
    }

    func start() {
        guard timer == nil else { return }

        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkForChanges()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func checkForChanges() {
        let currentCount = pasteboard.changeCount
        let currentFrontmostApp = NSWorkspace.shared.frontmostApplication?.localizedName

        // Check if clipboard changed
        if currentCount != lastChangeCount {
            lastChangeCount = currentCount

            // Use the app that was frontmost *before* this check,
            // as the copy likely happened before we detected the change
            let sourceApp = lastKnownFrontmostApp

            // Only handle string content
            if let content = pasteboard.string(forType: .string) {
                // Truncate if content exceeds max size to prevent memory issues
                let finalContent: String
                let isTruncated: Bool
                if content.utf8.count > maxContentSize {
                    // Find a safe truncation point (don't split UTF-8 characters)
                    let truncatedContent = String(content.utf8.prefix(maxContentSize)) ?? String(content.prefix(maxContentSize / 4))
                    finalContent = truncatedContent + "\n\n[Content truncated - original size: \(content.utf8.count) bytes]"
                    isTruncated = true
                } else {
                    finalContent = content
                    isTruncated = false
                }

                let representations = captureTextRepresentations(
                    fallbackContent: finalContent,
                    isTruncated: isTruncated
                )

                Task { @MainActor in
                    HistoryStore.shared.add(
                        finalContent,
                        sourceApp: sourceApp,
                        representations: representations
                    )
                }
            }
        }

        // Always update the last known frontmost app for the next check
        lastKnownFrontmostApp = currentFrontmostApp
    }

    func getCurrentContent() -> String? {
        return pasteboard.string(forType: .string)
    }

    func setContent(_ content: String) {
        pasteboard.clearContents()
        pasteboard.setString(content, forType: .string)
        lastChangeCount = pasteboard.changeCount
    }

    func setContent(_ item: ClipboardItem) {
        pasteboard.clearContents()

        if item.representations.isEmpty {
            pasteboard.setString(item.content, forType: .string)
        } else {
            let pasteboardItem = NSPasteboardItem()
            var hasPlainText = false

            for representation in item.representations {
                let type = NSPasteboard.PasteboardType(representation.type)
                pasteboardItem.setData(representation.data, forType: type)

                if isPlainTextType(representation.type) {
                    hasPlainText = true
                }
            }

            if !hasPlainText {
                pasteboardItem.setString(item.content, forType: .string)
            }

            pasteboard.writeObjects([pasteboardItem])
        }

        lastChangeCount = pasteboard.changeCount
    }

    private func captureTextRepresentations(
        fallbackContent: String,
        isTruncated: Bool
    ) -> [ClipboardRepresentation] {
        if isTruncated {
            return plainTextRepresentation(for: fallbackContent)
        }

        guard let item = pasteboard.pasteboardItems?.first else {
            return plainTextRepresentation(for: fallbackContent)
        }

        var totalBytes = 0
        var representations: [ClipboardRepresentation] = []

        for type in item.types where textPasteboardTypes.contains(type.rawValue) {
            guard let data = item.data(forType: type) else { continue }
            let nextTotal = totalBytes + data.count

            guard nextTotal <= maxRepresentationBytes else {
                continue
            }

            representations.append(
                ClipboardRepresentation(
                    type: type.rawValue,
                    data: data
                )
            )
            totalBytes = nextTotal
        }

        if !representations.contains(where: { isPlainTextType($0.type) }) {
            representations.append(contentsOf: plainTextRepresentation(for: fallbackContent))
        }

        return representations
    }

    private func plainTextRepresentation(for content: String) -> [ClipboardRepresentation] {
        guard let data = content.data(using: .utf8) else { return [] }

        return [
            ClipboardRepresentation(
                type: NSPasteboard.PasteboardType.string.rawValue,
                data: data
            )
        ]
    }

    private func isPlainTextType(_ type: String) -> Bool {
        type == NSPasteboard.PasteboardType.string.rawValue ||
            type == "public.utf8-plain-text" ||
            type == "public.utf16-plain-text" ||
            type == "NSStringPboardType"
    }
}
