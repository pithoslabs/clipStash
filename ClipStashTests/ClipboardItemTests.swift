import XCTest
@testable import ClipStash

final class ClipboardItemTests: XCTestCase {

    // MARK: - Initialization Tests

    func testInitialization() {
        let content = "Test content"
        let sourceApp = "Safari"
        let item = ClipboardItem(content: content, sourceApp: sourceApp)

        XCTAssertEqual(item.content, content)
        XCTAssertEqual(item.sourceApp, sourceApp)
        XCTAssertNotNil(item.id)
        XCTAssertNotNil(item.copiedAt)
        XCTAssertFalse(item.isStarred)
    }

    func testInitializationWithoutSourceApp() {
        let content = "Test content"
        let item = ClipboardItem(content: content)

        XCTAssertEqual(item.content, content)
        XCTAssertNil(item.sourceApp)
    }

    // MARK: - Preview Tests

    func testPreviewShortContent() {
        let content = "Short text"
        let item = ClipboardItem(content: content)

        XCTAssertEqual(item.preview, content)
    }

    func testPreviewLongContent() {
        let content = String(repeating: "a", count: 100)
        let item = ClipboardItem(content: content)

        XCTAssertTrue(item.preview.count <= 83) // 80 chars + "..."
        XCTAssertTrue(item.preview.hasSuffix("..."))
    }

    func testPreviewMultilineContent() {
        let content = "First line\nSecond line\nThird line"
        let item = ClipboardItem(content: content)

        XCTAssertEqual(item.preview, "First line")
    }

    func testPreviewTrimsWhitespace() {
        let content = "   Trimmed content   "
        let item = ClipboardItem(content: content)

        XCTAssertEqual(item.preview, "Trimmed content")
    }

    func testPreviewEmptyContent() {
        let item = ClipboardItem(content: "")

        XCTAssertEqual(item.preview, "")
    }

    // MARK: - Time Ago Tests

    func testTimeAgoReturnsString() {
        let item = ClipboardItem(content: "test")

        // RelativeDateTimeFormatter output varies by locale, just check it's not empty
        XCTAssertFalse(item.timeAgo.isEmpty)
    }

    // MARK: - Search Matching Tests

    func testMatchesCaseInsensitive() {
        let item = ClipboardItem(content: "Hello World")

        XCTAssertTrue(item.matches(query: "hello"))
        XCTAssertTrue(item.matches(query: "WORLD"))
        XCTAssertTrue(item.matches(query: "Hello"))
    }

    func testMatchesPartialContent() {
        let item = ClipboardItem(content: "https://github.com/pithoslabs")

        XCTAssertTrue(item.matches(query: "github"))
        XCTAssertTrue(item.matches(query: "pithos"))
        XCTAssertTrue(item.matches(query: "https"))
    }

    func testMatchesNoMatch() {
        let item = ClipboardItem(content: "Hello World")

        XCTAssertFalse(item.matches(query: "xyz"))
        XCTAssertFalse(item.matches(query: "foo"))
    }

    func testMatchesEmptyQuery() {
        let item = ClipboardItem(content: "Hello World")

        XCTAssertTrue(item.matches(query: ""))
    }

    // MARK: - Codable Tests

    func testEncodeDecode() throws {
        let representation = ClipboardRepresentation(
            type: "public.rtf",
            data: try XCTUnwrap("{\\rtf1 Test content}".data(using: .utf8))
        )
        let original = ClipboardItem(
            content: "Test content",
            sourceApp: "Safari",
            isStarred: true,
            representations: [representation]
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ClipboardItem.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.content, original.content)
        XCTAssertEqual(decoded.sourceApp, original.sourceApp)
        XCTAssertTrue(decoded.isStarred)
        XCTAssertEqual(decoded.representations, [representation])
    }

    func testDecodeLegacyItemDefaultsToUnstarred() throws {
        let json = """
        {
            "id": "00000000-0000-0000-0000-000000000001",
            "content": "Legacy content",
            "copiedAt": 0,
            "sourceApp": "Safari"
        }
        """

        let data = try XCTUnwrap(json.data(using: .utf8))
        let decoded = try JSONDecoder().decode(ClipboardItem.self, from: data)

        XCTAssertEqual(decoded.content, "Legacy content")
        XCTAssertFalse(decoded.isStarred)
        XCTAssertTrue(decoded.representations.isEmpty)
    }

    func testWithStarredPreservesItemData() throws {
        let representation = ClipboardRepresentation(
            type: "public.html",
            data: try XCTUnwrap("<strong>Test content</strong>".data(using: .utf8))
        )
        let original = ClipboardItem(
            content: "Test content",
            sourceApp: "Safari",
            representations: [representation]
        )
        let starred = original.withStarred(true)

        XCTAssertEqual(starred.id, original.id)
        XCTAssertEqual(starred.content, original.content)
        XCTAssertEqual(starred.copiedAt, original.copiedAt)
        XCTAssertEqual(starred.sourceApp, original.sourceApp)
        XCTAssertEqual(starred.representations, [representation])
        XCTAssertTrue(starred.isStarred)
    }

    // MARK: - Equatable Tests

    func testEqualItemsWithSameId() {
        let item1 = ClipboardItem(content: "test")
        let item2 = item1 // Same instance

        XCTAssertEqual(item1, item2)
    }

    func testDifferentItemsNotEqual() {
        let item1 = ClipboardItem(content: "test1")
        let item2 = ClipboardItem(content: "test2")

        XCTAssertNotEqual(item1, item2)
    }

    // MARK: - Edge Cases

    func testSpecialCharactersInContent() {
        let content = "Special chars: @#$%^&*(){}[]|\\:\";<>?,./`~"
        let item = ClipboardItem(content: content)

        XCTAssertEqual(item.content, content)
        XCTAssertTrue(item.matches(query: "@#$"))
    }

    func testUnicodeContent() {
        let content = "Unicode: 你好世界 🎉 émojis"
        let item = ClipboardItem(content: content)

        XCTAssertEqual(item.content, content)
        XCTAssertTrue(item.matches(query: "你好"))
        XCTAssertTrue(item.matches(query: "🎉"))
    }

    func testVeryLongContent() {
        let content = String(repeating: "a", count: 10000)
        let item = ClipboardItem(content: content)

        XCTAssertEqual(item.content.count, 10000)
        XCTAssertTrue(item.preview.count <= 83)
    }
}
