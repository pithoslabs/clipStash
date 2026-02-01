import AppKit
import Combine

final class ClipboardMonitor: ObservableObject {
    static let shared = ClipboardMonitor()

    private var timer: Timer?
    private var lastChangeCount: Int = 0
    private let pasteboard = NSPasteboard.general

    /// Maximum content size to store (1MB)
    private let maxContentSize = 1_000_000

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
}
