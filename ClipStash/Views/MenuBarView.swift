import SwiftUI

struct MenuBarView: View {
    @ObservedObject var historyStore = HistoryStore.shared
    @State private var isAccessibilityEnabled = AccessibilityHelper.isAccessibilityEnabled
    @State private var hoveredItemID: UUID?
    @State private var hoveredMenuItem: MenuHoverTarget?
    @AppStorage(HotkeyManager.enableRemoteDesktopPasteKey) private var enableRemoteDesktopPaste = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !isAccessibilityEnabled {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.yellow)
                        .font(.system(size: 20))

                    Text("Accessibility permission required")
                        .font(.system(size: 12, weight: .medium))

                    Button("Open Settings") {
                        AccessibilityHelper.openAccessibilitySettings()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
                .padding()
                .frame(maxWidth: .infinity)

                Divider()
            }

            if historyStore.saveError != nil {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.red)
                        .font(.system(size: 20))

                    Text("Failed to save history")
                        .font(.system(size: 12, weight: .medium))

                    Text("Changes may be lost on restart")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)

                    HStack(spacing: 8) {
                        Button("Retry") {
                            historyStore.retrySave()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)

                        Button("Dismiss") {
                            historyStore.dismissSaveError()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)

                Divider()
            }

            // Recent items preview
            if historyStore.items.isEmpty {
                Text("No clipboard history")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.top, 18)
                    .padding(.bottom, 14)
                    .frame(maxWidth: .infinity)
            } else {
                Text("Recent (\(historyStore.items.count) items)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                    .padding(.bottom, 4)

                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(historyStore.items) { item in
                            Button(action: {
                                // Copy to clipboard (user can then paste manually)
                                ClipboardMonitor.shared.setContent(item.content)
                            }) {
                                MenuHistoryRow(
                                    item: item,
                                    isHovered: hoveredItemID == item.id
                                )
                            }
                            .buttonStyle(.plain)
                            .onHover { hovering in
                                hoveredItemID = hovering ? item.id : nil
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                }
                .frame(maxHeight: 220)
                .onHover { hovering in
                    if !hovering {
                        hoveredItemID = nil
                    }
                }
            }

            Divider()
                .padding(.horizontal, 10)
                .padding(.vertical, 5)

            Toggle(isOn: $enableRemoteDesktopPaste) {
                MenuToggleRow(
                    title: "Use in Screen Sharing",
                    subtitle: "Paste Air clips into remote Macs",
                    systemImage: "rectangle.connected.to.line.below",
                    isHovered: hoveredMenuItem == .remoteDesktopToggle
                )
            }
            .toggleStyle(.switch)
            .controlSize(.small)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .onHover { hovering in
                hoveredMenuItem = hovering ? .remoteDesktopToggle : nil
            }

            Divider()
                .padding(.horizontal, 10)
                .padding(.vertical, 5)

            Button(action: {
                historyStore.clear()
            }) {
                MenuActionRow(
                    title: "Clear History",
                    systemImage: "trash",
                    isHovered: hoveredMenuItem == .clearHistory
                )
            }
            .buttonStyle(.plain)
            .disabled(historyStore.items.isEmpty)
            .opacity(historyStore.items.isEmpty ? 0.55 : 1.0)
            .onHover { hovering in
                hoveredMenuItem = hovering ? .clearHistory : nil
            }

            Divider()
                .padding(.horizontal, 10)
                .padding(.vertical, 5)

            Button(action: {
                NSApplication.shared.terminate(nil)
            }) {
                MenuActionRow(
                    title: "Quit ClipStash",
                    systemImage: "power",
                    isHovered: hoveredMenuItem == .quit
                )
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                hoveredMenuItem = hovering ? .quit : nil
            }
        }
        .padding(.bottom, 6)
        .frame(width: 260)
        .onAppear {
            isAccessibilityEnabled = AccessibilityHelper.isAccessibilityEnabled
        }
    }
}

private enum MenuHoverTarget {
    case remoteDesktopToggle
    case clearHistory
    case quit
}

private struct MenuToggleRow: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let isHovered: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)
        }
        .padding(.horizontal, 8)
        .frame(height: 40)
        .frame(maxWidth: .infinity, alignment: .leading)
        .menuHoverBackground(isHovered)
        .contentShape(Rectangle())
    }
}

private struct MenuHistoryRow: View {
    let item: ClipboardItem
    let isHovered: Bool

    var body: some View {
        HStack(spacing: 8) {
            Text(item.preview)
                .lineLimit(1)
                .font(.system(size: 12))
                .foregroundColor(.primary)

            Spacer(minLength: 8)

            if isHovered {
                Image(systemName: "doc.on.clipboard")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 8)
        .frame(height: 28)
        .frame(maxWidth: .infinity, alignment: .leading)
        .menuHoverBackground(isHovered)
        .contentShape(Rectangle())
    }
}

private struct MenuActionRow: View {
    let title: String
    let systemImage: String
    let isHovered: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
                .frame(width: 16)

            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.primary)

            Spacer()
        }
        .padding(.horizontal, 16)
        .frame(height: 28)
        .frame(maxWidth: .infinity, alignment: .leading)
        .menuHoverBackground(isHovered)
        .contentShape(Rectangle())
    }
}

private extension View {
    func menuHoverBackground(_ isHovered: Bool) -> some View {
        background(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(isHovered ? Color.accentColor.opacity(0.14) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .strokeBorder(isHovered ? Color.accentColor.opacity(0.24) : Color.clear, lineWidth: 1)
        )
    }
}
