import SwiftUI

struct ClipboardItemView: View {
    let entry: ClipboardEntry
    let isSelected: Bool
    let onCopy: () -> Void
    let onDelete: () -> Void
    let onTogglePin: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Content
            VStack(alignment: .leading, spacing: 6) {
                // Type badge and timestamp
                HStack(spacing: 8) {
                    // Pin indicator
                    if entry.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 9))
                            .foregroundColor(isSelected ? .white.opacity(0.9) : .orange)
                    }

                    // Type badge
                    Text(entry.type.rawValue)
                        .font(.system(size: 11))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isSelected ? Color.white.opacity(0.2) : typeColor.opacity(0.1))
                        .foregroundColor(isSelected ? .white : typeColor)
                        .cornerRadius(4)

                    Text(entry.formattedTime())
                        .font(.system(size: 11))
                        .foregroundColor(isSelected ? .white.opacity(0.7) : Color(nsColor: .secondaryLabelColor))

                    Spacer()
                }

                // Content preview
                Text(entry.content)
                    .font(.system(size: 13))
                    .foregroundColor(isSelected ? .white : Color(nsColor: .labelColor))
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .multilineTextAlignment(.leading)
            }

            // Action buttons
            HStack(spacing: 4) {
                Button(action: onTogglePin) {
                    Image(systemName: entry.isPinned ? "pin.slash" : "pin")
                        .font(.system(size: 13))
                        .foregroundColor(isSelected ? .white : Color(nsColor: .secondaryLabelColor))
                        .frame(width: 26, height: 26)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .opacity(isSelected || isHovered ? 1 : 0)

                Button(action: onCopy) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 13))
                        .foregroundColor(isSelected ? .white : Color(nsColor: .secondaryLabelColor))
                        .frame(width: 26, height: 26)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .opacity(isSelected || isHovered ? 1 : 0)

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 13))
                        .foregroundColor(isSelected ? .white : Color(nsColor: .secondaryLabelColor))
                        .frame(width: 26, height: 26)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .opacity(isSelected || isHovered ? 1 : 0)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Rectangle()
                .fill(isSelected ? Color.accentColor : (isHovered ? Color(nsColor: .controlBackgroundColor) : Color.clear))
        )
        .padding(.horizontal, 0)
        .onHover { hovering in
            isHovered = hovering
        }
    }

    private var typeColor: Color {
        switch entry.type {
        case .code:
            return .blue
        case .image:
            return .purple
        case .richText:
            return .green
        case .text:
            return .gray
        }
    }
}
