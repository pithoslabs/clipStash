import AppKit
import Combine

final class ClipboardMonitor: ObservableObject {
    static let shared = ClipboardMonitor()

    private var timer: Timer?
    private var lastChangeCount: Int = 0
    private let pasteboard = NSPasteboard.general

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

        HistoryStore.shared.add(content, sourceApp: sourceApp)
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
