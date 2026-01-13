import Foundation

// Shared state for keyboard handling - must be a class so it's passed by reference
class PopupState: ObservableObject {
    static let shared = PopupState()
    @Published var selectedIndex = 0
    @Published var searchQuery = ""
    @Published var hoveredIndex: Int? = nil

    var onItemSelected: ((ClipboardItem) -> Void)?
    var onDismiss: (() -> Void)?

    func reset() {
        selectedIndex = 0
        searchQuery = ""
        hoveredIndex = nil
    }
}
