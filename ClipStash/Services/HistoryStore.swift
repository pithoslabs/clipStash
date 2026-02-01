import Foundation
import Combine
import os.lock

@MainActor
final class HistoryStore: ObservableObject {
    static let shared = HistoryStore()

    @Published private(set) var items: [ClipboardItem] = []
    @Published private(set) var saveError: Error?

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
    private let legacyStorageURL: URL  // For migration from unencrypted storage
    private var cleanupTimer: Timer?

    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appFolder = appSupport.appendingPathComponent("ClipStash", isDirectory: true)

        try? FileManager.default.createDirectory(at: appFolder, withIntermediateDirectories: true)

        self.storageURL = appFolder.appendingPathComponent("history.encrypted")
        self.legacyStorageURL = appFolder.appendingPathComponent("history.json")
        migrateFromLegacyStorageIfNeeded()
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

    /// Migrates from unencrypted history.json to encrypted storage
    private func migrateFromLegacyStorageIfNeeded() {
        let fileManager = FileManager.default

        // Check if legacy file exists and new encrypted file doesn't
        guard fileManager.fileExists(atPath: legacyStorageURL.path),
              !fileManager.fileExists(atPath: storageURL.path) else {
            return
        }

        do {
            // Load from legacy unencrypted file
            let legacyData = try Data(contentsOf: legacyStorageURL)
            let legacyItems = try JSONDecoder().decode([ClipboardItem].self, from: legacyData)

            // Save to new encrypted format
            let jsonData = try JSONEncoder().encode(legacyItems)
            let encryptedData = try EncryptionHelper.encrypt(jsonData)
            try encryptedData.write(to: storageURL, options: .atomic)

            // Remove legacy file after successful migration
            try? fileManager.removeItem(at: legacyStorageURL)
        } catch {
            // Migration failed - legacy file remains, will try again next launch
        }
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: storageURL.path) else { return }

        do {
            let encryptedData = try Data(contentsOf: storageURL)
            let jsonData = try EncryptionHelper.decrypt(encryptedData)
            items = try JSONDecoder().decode([ClipboardItem].self, from: jsonData)
            updateHasItems()
        } catch {
            print("Failed to load history: \(error)")
        }
    }

    private func save() {
        let maxRetries = 3
        var lastError: Error?

        for attempt in 1...maxRetries {
            do {
                let jsonData = try JSONEncoder().encode(items)
                let encryptedData = try EncryptionHelper.encrypt(jsonData)
                try encryptedData.write(to: storageURL, options: .atomic)
                // Success - clear any previous error
                if saveError != nil {
                    saveError = nil
                }
                return
            } catch {
                lastError = error
                if attempt < maxRetries {
                    // Brief delay before retry
                    Thread.sleep(forTimeInterval: 0.1 * Double(attempt))
                }
            }
        }

        // All retries failed
        saveError = lastError
    }

    /// Manually retry saving after a failure
    func retrySave() {
        save()
    }

    /// Dismiss the save error without retrying
    func dismissSaveError() {
        saveError = nil
    }
}
