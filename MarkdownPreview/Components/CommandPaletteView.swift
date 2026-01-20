// Command Palette View
import SwiftUI

struct CommandPaletteView: View {
    @Binding var isPresented: Bool
    let theme: Theme
    let actions: [(String, String, () -> Void)]
    
    @State private var searchText = ""
    
    private var filteredActions: [(String, String, () -> Void)] {
        guard !searchText.isEmpty else { return actions }
        return actions.filter { $0.0.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        ZStack {
            // Backdrop
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture { isPresented = false }
            
            // Palette
            VStack(spacing: 0) {
                searchField
                actionsList
            }
            .frame(width: 400)
            .background(Color(hex: theme.bg))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.5), radius: 20)
        }
        .onExitCommand { isPresented = false }
    }
    
    private var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Color(hex: theme.comment))
            TextField("Type a command...", text: $searchText)
                .textFieldStyle(.plain)
        }
        .padding(12)
        .background(Color(hex: theme.editorBg))
    }
    
    private var actionsList: some View {
        ScrollView {
            VStack(spacing: 2) {
                ForEach(filteredActions.indices, id: \.self) { index in
                    ActionRowView(
                        title: filteredActions[index].0,
                        shortcut: filteredActions[index].1,
                        theme: theme
                    ) {
                        filteredActions[index].2()
                        isPresented = false
                    }
                }
            }
        }
        .frame(maxHeight: 300)
    }
}

// MARK: - Action Row
struct ActionRowView: View {
    let title: String
    let shortcut: String
    let theme: Theme
    let action: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                Spacer()
                Text(shortcut)
                    .foregroundColor(Color(hex: theme.comment))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isHovering ? Color.white.opacity(0.05) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }
}
