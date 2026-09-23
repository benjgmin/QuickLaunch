import SwiftUI

struct AppRow: View {
    let app: AppInfo
    let isSelected: Bool
    let index: Int
    
    var body: some View {
        HStack(spacing: 14) {
            Image(nsImage: app.icon)
                .resizable()
                .frame(width: 36, height: 36)
                .cornerRadius(8)
                .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(app.name)
                        .font(.system(size: 14, weight: .medium))
                        .lineLimit(1)
                    
                    if app.isFile {
                        Text("FILE")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.15))
                            .cornerRadius(4)
                    }
                }
                
                Text(app.path)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            if isSelected {
                Text("↵")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(6)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
        )
        .contentShape(Rectangle())
    }
}

struct ClipboardRow: View {
    let item: ClipboardItem
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.on.clipboard")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .frame(width: 32, height: 32)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.preview)
                    .font(.system(size: 13))
                    .lineLimit(1)
                
                Text(item.timeAgo)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isSelected {
                Text("↵")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(6)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
        )
        .contentShape(Rectangle())
    }
}

struct EmojiRow: View {
    let emoji: EmojiItem
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 14) {
            Text(emoji.emoji)
                .font(.system(size: 28))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(emoji.name)
                    .font(.system(size: 13, weight: .medium))
                
                Text(emoji.keywords.joined(separator: ", "))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            if isSelected {
                Text("↵")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(6)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
        )
        .contentShape(Rectangle())
    }
}

struct SystemCommandRow: View {
    let command: SystemCommand
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: command.icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(command.color)
                .frame(width: 36, height: 36)
                .background(command.color.opacity(0.15))
                .cornerRadius(8)
            
            Text(command.name)
                .font(.system(size: 14, weight: .medium))
            
            Spacer()
            
            if isSelected {
                Text("↵")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(6)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
        )
        .contentShape(Rectangle())
    }
}

struct ModeHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold))
            Spacer()
        }
        .foregroundColor(.secondary)
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 6)
    }
}

struct ShortcutHint: View {
    let prefix: String
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            Text(prefix)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.secondary.opacity(0.15))
                .cornerRadius(4)
            
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
    }
}

struct KeyHandler: NSViewRepresentable {
    let onEvent: (NSEvent) -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = KeyCaptureView()
        view.onEvent = onEvent
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
    
    class KeyCaptureView: NSView {
        var onEvent: ((NSEvent) -> Void)?
        override var acceptsFirstResponder: Bool { true }
        override func keyDown(with event: NSEvent) {
            onEvent?(event)
        }
    }
}
