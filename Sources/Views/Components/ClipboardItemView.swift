import SwiftUI
import AppKit

struct ClipboardItemView: View {
    let entry: ClipboardEntry
    let isHovered: Bool
    var isSelected: Bool = false
    let onPaste: () -> Void
    let onPin: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // Type badge
            Text(entry.type.displayName)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(entry.type.badgeColor)
                .cornerRadius(4)

            // Content area
            VStack(alignment: .leading, spacing: 4) {
                // Content preview (with image support)
                if entry.type == .image, let imageData = entry.imageData {
                    ImagePreview(imageData: imageData)
                } else {
                    Text(entry.preview)
                        .font(.system(size: 13))
                        .lineLimit(2)
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // Timestamp
                Text(entry.relativeTimestamp)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            // Pin indicator or action buttons
            if entry.isPinned && !isHovered {
                Image(systemName: "pin.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.orange)
            } else if isHovered {
                HStack(spacing: 8) {
                    // Pin/Unpin button
                    Button(action: onPin) {
                        Image(systemName: entry.isPinned ? "pin.slash" : "pin")
                            .font(.system(size: 12))
                            .foregroundColor(entry.isPinned ? .orange : .secondary)
                    }
                    .buttonStyle(.plain)
                    .help(entry.isPinned ? "Unpin" : "Pin")

                    // Copy button
                    Button(action: {
                        // Copy to clipboard without pasting
                        let pasteboard = NSPasteboard.general
                        pasteboard.clearContents()
                        pasteboard.setString(entry.content, forType: .string)
                    }) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Copy")

                    // Delete button
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                    .help("Delete")
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            isSelected
                ? Color(NSColor.selectedContentBackgroundColor).opacity(0.5)
                : (isHovered ? Color(NSColor.selectedContentBackgroundColor).opacity(0.3) : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onPaste()
        }
    }
}

struct ImagePreview: View {
    let imageData: Data

    var body: some View {
        if let nsImage = NSImage(data: imageData) {
            Image(nsImage: nsImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 200, maxHeight: 80)
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )
        } else {
            Text("Image")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        }
    }
}
