import SwiftUI

struct MenuBarView: View {
    @ObservedObject var historyStore = HistoryStore.shared
    @State private var isAccessibilityEnabled = AccessibilityHelper.isAccessibilityEnabled

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

            // Recent items preview
            if historyStore.items.isEmpty {
                Text("No clipboard history")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
            } else {
                Text("Recent (\(historyStore.items.count) items)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                    .padding(.bottom, 4)

                ForEach(historyStore.items.prefix(5)) { item in
                    Button(action: {
                        // Copy to clipboard (user can then paste manually)
                        ClipboardMonitor.shared.setContent(item.content)
                    }) {
                        Text(item.preview)
                            .lineLimit(1)
                            .font(.system(size: 12))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                }
            }

            Divider()
                .padding(.vertical, 4)

            Button(action: {
                historyStore.clear()
            }) {
                Label("Clear History", systemImage: "trash")
                    .font(.system(size: 12))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .disabled(historyStore.items.isEmpty)

            Divider()
                .padding(.vertical, 4)

            Button(action: {
                NSApplication.shared.terminate(nil)
            }) {
                Label("Quit ClipStash", systemImage: "power")
                    .font(.system(size: 12))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
        }
        .frame(width: 250)
        .onAppear {
            isAccessibilityEnabled = AccessibilityHelper.isAccessibilityEnabled
        }
    }
}
