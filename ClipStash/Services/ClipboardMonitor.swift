import AppKit
import Combine

final class ClipboardMonitor: ObservableObject {
    static let shared = ClipboardMonitor()

    private var timer: Timer?
    private var lastChangeCount: Int = 0
    private let pasteboard = NSPasteboard.general

    /// Maximum content size to store (1MB)
    private let maxContentSize = 1_000_000

    private init() {
        lastChangeCount = pasteboard.changeCount
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

        guard currentCount != lastChangeCount else { return }
        lastChangeCount = currentCount

        // Get the current frontmost app
        let sourceApp = NSWorkspace.shared.frontmostApplication?.localizedName

        // Only handle string content
        guard let content = pasteboard.string(forType: .string) else { return }

        // Truncate if content exceeds max size to prevent memory issues
        let finalContent: String
        if content.utf8.count > maxContentSize {
            // Find a safe truncation point (don't split UTF-8 characters)
            let truncatedContent = String(content.utf8.prefix(maxContentSize)) ?? String(content.prefix(maxContentSize / 4))
            finalContent = truncatedContent + "\n\n[Content truncated - original size: \(content.utf8.count) bytes]"
        } else {
            finalContent = content
        }

        Task { @MainActor in
            HistoryStore.shared.add(finalContent, sourceApp: sourceApp)
        }
    }

    func getCurrentContent() -> String? {
        return pasteboard.string(forType: .string)
    }

    func setContent(_ content: String) {
        pasteboard.clearContents()
        pasteboard.setString(content, forType: .string)
        lastChangeCount = pasteboard.changeCount
    }
}
