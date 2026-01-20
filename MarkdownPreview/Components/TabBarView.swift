// Tab Bar View
import SwiftUI

struct TabBarView: View {
    let tabs: [Tab]
    let selectedId: UUID?
    let theme: Theme
    let onSelect: (Tab) -> Void
    let onClose: (Tab) -> Void
    let onPin: (Tab) -> Void
    let onNewTab: () -> Void
    let onToggleSidebar: () -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            Button(action: onToggleSidebar) {
                Image(systemName: "sidebar.left")
                    .font(.system(size: 12))
            }
            .buttonStyle(.plain)
            .foregroundColor(Color(hex: theme.comment))
            .padding(.horizontal, 10)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 1) {
                    ForEach(tabs) { tab in
                        TabButtonView(
                            tab: tab,
                            isSelected: tab.id == selectedId,
                            theme: theme,
                            onSelect: { onSelect(tab) },
                            onClose: { onClose(tab) },
                            onPin: { onPin(tab) }
                        )
                    }
                }
            }
            
            Button(action: onNewTab) {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .medium))
            }
            .buttonStyle(AnimatedButtonStyle(color: Color(hex: theme.comment)))
            .padding(.horizontal, 12)
            
            Spacer()
        }
        .padding(.vertical, 6)
        .background(Color(hex: theme.bg).opacity(0.8))
    }
}

// MARK: - Tab Button
struct TabButtonView: View {
    let tab: Tab
    let isSelected: Bool
    let theme: Theme
    let onSelect: () -> Void
    let onClose: () -> Void
    let onPin: () -> Void
    
    @State private var isHovering = false
    @State private var isCloseHovering = false
    
    var body: some View {
        HStack(spacing: 6) {
            if tab.isPinned {
                Image(systemName: "pin.fill")
                    .font(.system(size: 9))
                    .foregroundColor(Color(hex: theme.accent))
            }
            
            Image(systemName: "doc.text")
                .font(.system(size: 11))
                .foregroundColor(Color(hex: theme.comment))
            
            Text(tab.name)
                .font(.system(size: 12))
                .lineLimit(1)
            
            if tab.isModified {
                Circle()
                    .fill(Color(hex: theme.string))
                    .frame(width: 8, height: 8)
            }
            
            if isHovering || isSelected {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .semibold))
                }
                .buttonStyle(.plain)
                .opacity(0.6)
                .foregroundColor(isCloseHovering ? .red : Color(hex: theme.text))
                .onHover { isCloseHovering = $0 }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color(hex: theme.comment).opacity(0.3) : (isHovering ? Color.white.opacity(0.05) : Color.clear))
        )
        .foregroundColor(Color(hex: isSelected ? theme.text : theme.comment))
        .scaleEffect(isSelected ? 1.02 : 1)
        .animation(.spring(response: 0.2), value: isSelected)
        .onTapGesture { onSelect() }
        .onHover { isHovering = $0 }
        .contextMenu {
            Button(tab.isPinned ? "Unpin" : "Pin") { onPin() }
            Button("Close") { onClose() }
        }
    }
}

// MARK: - Animated Button Style
struct AnimatedButtonStyle: ButtonStyle {
    let color: Color
    @State private var isHovering = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(color)
            .scaleEffect(configuration.isPressed ? 0.85 : (isHovering ? 1.1 : 1))
            .animation(.spring(response: 0.2), value: configuration.isPressed)
            .onHover { isHovering = $0 }
    }
}
