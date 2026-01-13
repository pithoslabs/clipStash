import SwiftUI

struct ClipboardItemRow: View {
    let item: ClipboardItem
    let index: Int
    let isSelected: Bool
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: 14) {
            // Quick select number with Liquid Glass pill
            Text("\(index + 1)")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(isSelected ? .white : .secondary)
                .frame(width: 24, height: 24)
                .background(
                    Circle()
                        .fill(isSelected ? Color.accentColor : Color.primary.opacity(0.08))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(item.preview)
                    .font(.system(size: 14))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    Text(item.timeAgo)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.tertiary)

                    if let app = item.sourceApp {
                        Text("•")
                            .foregroundStyle(.quaternary)
                        Text(app)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            Spacer()

            // Paste hint on selected item
            if isSelected {
                Image(systemName: "return")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.tertiary)
                    .padding(.trailing, 4)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isSelected ?
                    Color.accentColor.opacity(colorScheme == .dark ? 0.25 : 0.15) :
                    Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(isSelected ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .contentShape(Rectangle())
    }
}
