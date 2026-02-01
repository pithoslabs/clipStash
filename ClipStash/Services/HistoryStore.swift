import Foundation
import Combine
import os.lock

@MainActor
final class HistoryStore: ObservableObject {
    static let shared = HistoryStore()

    @Published private(set) var items: [ClipboardItem] = []

    // Thread-safe check for whether history has items (for use from non-main-actor contexts)
    private nonisolated(unsafe) var _hasItems: Bool = false
    private let _hasItemsLock = OSAllocatedUnfairLock()

    nonisolated var hasItems: Bool {
        _hasItemsLock.withLock { _hasItems }
    }

    private func updateHasItems() {
        let hasItems = !items.isEmpty
        _hasItemsLock.withLock {
            _hasItems = hasItems
        }
    }

    private let maxItems = 15
    private let maxAge: TimeInterval = 24 * 60 * 60 // 24 hours
    private let storageURL: URL
    private var cleanupTimer: Timer?

    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appFolder = appSupport.appendingPathComponent("ClipStash", isDirectory: true)

        try? FileManager.default.createDirectory(at: appFolder, withIntermediateDirectories: true)

        self.storageURL = appFolder.appendingPathComponent("history.json")
        load()
        startCleanupTimer()
    }

    func add(_ content: String, sourceApp: String? = nil) {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Don't add duplicates of the most recent item
        if let last = items.first, last.content == trimmed {
            return
        }

        // Remove any existing item with same content
        items.removeAll { $0.content == trimmed }

        let item = ClipboardItem(content: trimmed, sourceApp: sourceApp)
        items.insert(item, at: 0)

        // Enforce max items
        if items.count > maxItems {
            items = Array(items.prefix(maxItems))
        }

        updateHasItems()
        save()
    }

    func remove(_ item: ClipboardItem) {
        items.removeAll { $0.id == item.id }
        updateHasItems()
        save()
    }

    func clear() {
        items.removeAll()
        updateHasItems()
        save()
    }

    func search(_ query: String) -> [ClipboardItem] {
        guard !query.isEmpty else { return items }
        return items.filter { $0.matches(query: query) }
    }

    func cleanup() {
        let cutoff = Date().addingTimeInterval(-maxAge)
        let before = items.count
        items.removeAll { $0.copiedAt < cutoff }
        if items.count != before {
            updateHasItems()
            save()
        }
    }

    private func startCleanupTimer() {
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: 60 * 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.cleanup()
            }
        }
        // Run cleanup immediately on start
        cleanup()
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: storageURL.path) else { return }

        do {
            let data = try Data(contentsOf: storageURL)
            items = try JSONDecoder().decode([ClipboardItem].self, from: data)
            updateHasItems()
        } catch {
            print("Failed to load history: \(error)")
        }
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(items)
            try data.write(to: storageURL, options: .atomic)
        } catch {
            print("Failed to save history: \(error)")
        }
    }
}
