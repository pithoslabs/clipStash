import SwiftUI

struct PopupView: View {
    @ObservedObject var historyStore = HistoryStore.shared
    @ObservedObject var state = PopupState.shared
    @FocusState private var isSearchFocused: Bool
    @Environment(\.colorScheme) var colorScheme

    var onItemSelected: ((ClipboardItem) -> Void)?
    var onDismiss: (() -> Void)?

    private var filteredItems: [ClipboardItem] {
        historyStore.search(state.searchQuery)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Liquid Glass Search bar
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.tertiary)
                    .font(.system(size: 15, weight: .medium))

                TextField("Search clipboard...", text: $state.searchQuery)
                    .textFieldStyle(.plain)
                    .font(.system(size: 15))
                    .focused($isSearchFocused)
                    .onChange(of: state.searchQuery) { _, _ in
                        state.selectedIndex = 0
                    }

                if !state.searchQuery.isEmpty {
                    Button(action: { state.searchQuery = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.tertiary)
                            .font(.system(size: 14))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            // Subtle separator
            Rectangle()
                .fill(.quaternary)
                .frame(height: 0.5)

            // Items list
            if filteredItems.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc.on.clipboard")
                        .font(.system(size: 40, weight: .light))
                        .foregroundStyle(.tertiary)
                    Text(state.searchQuery.isEmpty ? "No clipboard history" : "No matches")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 1) {
                            ForEach(Array(filteredItems.enumerated()), id: \.element.id) { index, item in
                                ClipboardItemRow(
                                    item: item,
                                    index: index,
                                    isSelected: index == state.selectedIndex
                                )
                                .id(index)
                                .onHover { hovering in
                                    state.hoveredIndex = hovering ? index : nil
                                }
                            }
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 8)
                    }
                    .onChange(of: state.selectedIndex) { _, newValue in
                        withAnimation(.easeOut(duration: 0.15)) {
                            proxy.scrollTo(newValue, anchor: .center)
                        }
                    }
                }
            }

            // Subtle separator
            Rectangle()
                .fill(.quaternary)
                .frame(height: 0.5)

            // Liquid Glass Footer
            HStack(spacing: 20) {
                Label("Navigate", systemImage: "arrow.up.arrow.down")
                Label("Paste", systemImage: "return")
                Label("Cancel", systemImage: "escape")
            }
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(.tertiary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .frame(width: 420, height: 380)
        .background(LiquidGlassBackground())
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.25), radius: 30, x: 0, y: 15)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.white.opacity(colorScheme == .dark ? 0.15 : 0.4), lineWidth: 0.5)
        )
        .onAppear {
            isSearchFocused = true
            state.selectedIndex = 0
        }
    }

    private func selectItem(_ item: ClipboardItem) {
        onItemSelected?(item)
    }

    func handleMouseDown(_ event: NSEvent) -> Bool {
        // If mouse is hovering over an item, select it
        if let hoveredIndex = state.hoveredIndex,
           hoveredIndex < filteredItems.count {
            selectItem(filteredItems[hoveredIndex])
            return true
        }
        return false
    }

    func handleKeyDown(_ event: NSEvent) -> Bool {
        switch Int(event.keyCode) {
        case 125: // Down arrow
            if state.selectedIndex < filteredItems.count - 1 {
                state.selectedIndex += 1
            }
            return true

        case 126: // Up arrow
            if state.selectedIndex > 0 {
                state.selectedIndex -= 1
            }
            return true

        case 36: // Return/Enter
            if !filteredItems.isEmpty && state.selectedIndex < filteredItems.count {
                selectItem(filteredItems[state.selectedIndex])
            }
            return true

        case 53: // Escape
            onDismiss?()
            return true

        default:
            // Check for Cmd+1 through Cmd+9
            if event.modifierFlags.contains(.command) {
                if let number = Int(event.characters ?? ""), number >= 1 && number <= 9 {
                    let index = number - 1
                    if index < filteredItems.count {
                        selectItem(filteredItems[index])
                    }
                    return true
                }
            }
            return false
        }
    }
}

// Liquid Glass background effect
struct LiquidGlassBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .hudWindow
        view.blendingMode = .behindWindow
        view.state = .active
        view.wantsLayer = true
        view.layer?.cornerRadius = 16
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
