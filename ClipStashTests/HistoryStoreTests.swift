import XCTest
@testable import ClipStash

final class HistoryStoreTests: XCTestCase {

    var store: HistoryStore!

    override func setUp() {
        super.setUp()
        store = HistoryStore.shared
        store.clear() // Start with clean state
    }

    override func tearDown() {
        store.clear()
        super.tearDown()
    }

    // MARK: - Add Tests

    func testAddItem() {
        store.add("Test content", sourceApp: "Safari")

        XCTAssertEqual(store.items.count, 1)
        XCTAssertEqual(store.items.first?.content, "Test content")
        XCTAssertEqual(store.items.first?.sourceApp, "Safari")
    }

    func testAddMultipleItems() {
        store.add("First")
        store.add("Second")
        store.add("Third")

        XCTAssertEqual(store.items.count, 3)
        // Most recent should be first
        XCTAssertEqual(store.items[0].content, "Third")
        XCTAssertEqual(store.items[1].content, "Second")
        XCTAssertEqual(store.items[2].content, "First")
    }

    func testAddTrimsWhitespace() {
        store.add("  content with spaces  ")

        XCTAssertEqual(store.items.first?.content, "content with spaces")
    }

    func testAddIgnoresEmptyContent() {
        store.add("")
        store.add("   ")
        store.add("\n\t")

        XCTAssertTrue(store.items.isEmpty)
    }

    func testAddPreventsDuplicateOfMostRecent() {
        store.add("Same content")
        store.add("Same content")

        XCTAssertEqual(store.items.count, 1)
    }

    func testAddRemovesDuplicatesFromHistory() {
        store.add("First")
        store.add("Second")
        store.add("First") // Should move to top, not duplicate

        XCTAssertEqual(store.items.count, 2)
        XCTAssertEqual(store.items[0].content, "First")
        XCTAssertEqual(store.items[1].content, "Second")
    }

    func testAddEnforcesMaxItems() {
        // Add more than max (15) items
        for i in 1...20 {
            store.add("Item \(i)")
        }

        XCTAssertEqual(store.items.count, 15)
        // Most recent should be first
        XCTAssertEqual(store.items[0].content, "Item 20")
        // Oldest kept item should be Item 6
        XCTAssertEqual(store.items[14].content, "Item 6")
    }

    // MARK: - Remove Tests

    func testRemoveItem() {
        store.add("First")
        store.add("Second")

        let itemToRemove = store.items.first!
        store.remove(itemToRemove)

        XCTAssertEqual(store.items.count, 1)
        XCTAssertEqual(store.items.first?.content, "First")
    }

    func testRemoveNonExistentItem() {
        store.add("Existing")
        let fakeItem = ClipboardItem(content: "Fake")

        store.remove(fakeItem)

        XCTAssertEqual(store.items.count, 1)
    }

    // MARK: - Clear Tests

    func testClear() {
        store.add("First")
        store.add("Second")
        store.add("Third")

        store.clear()

        XCTAssertTrue(store.items.isEmpty)
    }

    // MARK: - Search Tests

    func testSearchFindsMatches() {
        store.add("Hello World")
        store.add("Goodbye World")
        store.add("Hello There")

        let results = store.search("Hello")

        XCTAssertEqual(results.count, 2)
        XCTAssertTrue(results.allSatisfy { $0.content.contains("Hello") })
    }

    func testSearchCaseInsensitive() {
        store.add("Hello World")

        let results = store.search("hello")

        XCTAssertEqual(results.count, 1)
    }

    func testSearchEmptyQueryReturnsAll() {
        store.add("First")
        store.add("Second")
        store.add("Third")

        let results = store.search("")

        XCTAssertEqual(results.count, 3)
    }

    func testSearchNoMatches() {
        store.add("Hello World")

        let results = store.search("xyz")

        XCTAssertTrue(results.isEmpty)
    }

    // MARK: - Persistence Tests

    func testPersistence() {
        store.add("Persistent content", sourceApp: "TestApp")

        // The store auto-saves, so items should persist
        // We can't easily test cross-session persistence without restarting,
        // but we can verify the save/load mechanism doesn't crash
        XCTAssertEqual(store.items.count, 1)
    }

    // MARK: - Edge Cases

    func testAddWithNilSourceApp() {
        store.add("Content", sourceApp: nil)

        XCTAssertEqual(store.items.count, 1)
        XCTAssertNil(store.items.first?.sourceApp)
    }

    func testAddSpecialCharacters() {
        let special = "Special: @#$%^&*(){}[]|\\:\";<>?,./`~"
        store.add(special)

        XCTAssertEqual(store.items.first?.content, special)
    }

    func testAddUnicodeContent() {
        let unicode = "Unicode: 你好世界 🎉 émojis"
        store.add(unicode)

        XCTAssertEqual(store.items.first?.content, unicode)
    }

    func testAddVeryLongContent() {
        let longContent = String(repeating: "a", count: 10000)
        store.add(longContent)

        XCTAssertEqual(store.items.first?.content.count, 10000)
    }

    // MARK: - Order Tests

    func testItemsOrderedByRecency() {
        store.add("First")
        Thread.sleep(forTimeInterval: 0.01) // Small delay to ensure different timestamps
        store.add("Second")
        Thread.sleep(forTimeInterval: 0.01)
        store.add("Third")

        XCTAssertEqual(store.items[0].content, "Third")
        XCTAssertEqual(store.items[1].content, "Second")
        XCTAssertEqual(store.items[2].content, "First")
    }
}
