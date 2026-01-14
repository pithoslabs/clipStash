import XCTest
import Combine
@testable import ClipStash

final class PopupStateTests: XCTestCase {

    var state: PopupState!

    override func setUp() {
        super.setUp()
        state = PopupState.shared
        state.reset()
    }

    override func tearDown() {
        state.reset()
        state.onItemSelected = nil
        state.onDismiss = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialSelectedIndex() {
        XCTAssertEqual(state.selectedIndex, 0)
    }

    func testInitialSearchQuery() {
        XCTAssertEqual(state.searchQuery, "")
    }

    func testInitialHoveredIndex() {
        XCTAssertNil(state.hoveredIndex)
    }

    // MARK: - Reset Tests

    func testReset() {
        state.selectedIndex = 5
        state.searchQuery = "test"
        state.hoveredIndex = 3

        state.reset()

        XCTAssertEqual(state.selectedIndex, 0)
        XCTAssertEqual(state.searchQuery, "")
        XCTAssertNil(state.hoveredIndex)
    }

    // MARK: - Property Modification Tests

    func testSelectedIndexModification() {
        state.selectedIndex = 3

        XCTAssertEqual(state.selectedIndex, 3)
    }

    func testSearchQueryModification() {
        state.searchQuery = "search term"

        XCTAssertEqual(state.searchQuery, "search term")
    }

    func testHoveredIndexModification() {
        state.hoveredIndex = 2

        XCTAssertEqual(state.hoveredIndex, 2)

        state.hoveredIndex = nil

        XCTAssertNil(state.hoveredIndex)
    }

    // MARK: - Callback Tests

    func testOnItemSelectedCallback() {
        var callbackCalled = false
        var receivedItem: ClipboardItem?

        state.onItemSelected = { item in
            callbackCalled = true
            receivedItem = item
        }

        let testItem = ClipboardItem(content: "Test")
        state.onItemSelected?(testItem)

        XCTAssertTrue(callbackCalled)
        XCTAssertEqual(receivedItem?.content, "Test")
    }

    func testOnDismissCallback() {
        var callbackCalled = false

        state.onDismiss = {
            callbackCalled = true
        }

        state.onDismiss?()

        XCTAssertTrue(callbackCalled)
    }

    func testCallbacksInitiallyNil() {
        let freshState = PopupState.shared
        freshState.reset()
        freshState.onItemSelected = nil
        freshState.onDismiss = nil

        // Calling nil callbacks should not crash
        freshState.onItemSelected?(ClipboardItem(content: "Test"))
        freshState.onDismiss?()

        // If we get here, no crash occurred
        XCTAssertTrue(true)
    }

    // MARK: - Observable Tests

    func testPublishedPropertyChanges() {
        let expectation = XCTestExpectation(description: "Property change observed")

        let cancellable = state.$selectedIndex.sink { newValue in
            if newValue == 5 {
                expectation.fulfill()
            }
        }

        state.selectedIndex = 5

        wait(for: [expectation], timeout: 1.0)
        cancellable.cancel()
    }

    // MARK: - Edge Cases

    func testNegativeSelectedIndex() {
        state.selectedIndex = -1

        XCTAssertEqual(state.selectedIndex, -1)
        // Note: The UI layer should handle bounds checking
    }

    func testLargeSelectedIndex() {
        state.selectedIndex = 1000

        XCTAssertEqual(state.selectedIndex, 1000)
        // Note: The UI layer should handle bounds checking
    }

    func testEmptySearchQuery() {
        state.searchQuery = ""

        XCTAssertEqual(state.searchQuery, "")
    }

    func testSearchQueryWithSpecialCharacters() {
        state.searchQuery = "@#$%^&*()"

        XCTAssertEqual(state.searchQuery, "@#$%^&*()")
    }

    func testSearchQueryWithUnicode() {
        state.searchQuery = "你好 🎉"

        XCTAssertEqual(state.searchQuery, "你好 🎉")
    }
}
