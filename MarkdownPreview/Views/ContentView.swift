// Main Content View
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var findText = ""
    @State private var replaceText = ""
    @State private var showCloseAlert = false
    @State private var tabToClose: Tab?
    @State private var splitRatio: CGFloat = 0.5
    
    var body: some View {
        ZStack {
            mainContent
            overlays
        }
        .toolbar { ToolbarView(appState: appState) }
        .navigationTitle(appState.selectedTab?.name ?? "Render.md")
        .preferredColorScheme(.dark)
        .frame(minWidth: 800, minHeight: 600)
        .background(Color(hex: appState.theme.bg))
        .onAppear { appState.loadState() }
        .onDisappear { appState.saveState() }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didEnterFullScreenNotification)) { _ in
            appState.isFullscreen = true
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didExitFullScreenNotification)) { _ in
            appState.isFullscreen = false
        }
        .alert("Unsaved Changes", isPresented: $showCloseAlert) {
            Button("Save") { saveAndClose() }
            Button("Don't Save", role: .destructive) { forceClose() }
            Button("Cancel", role: .cancel) { tabToClose = nil }
        } message: {
            Text("Save changes to \"\(tabToClose?.name ?? "")\"?")
        }
        .background(
            KeyboardHandler(
                onNewTab: { appState.newTab() },
                onCloseTab: { confirmClose() },
                onSave: { saveCurrentTab() },
                onFind: { appState.showFind.toggle() },
                onTogglePreview: { appState.showPreview.toggle() },
                onCommandPalette: { appState.showCommandPalette = true },
                onZenMode: { withAnimation { appState.zenMode.toggle() } },
                onIncreaseFontSize: { appState.fontSize = min(appState.fontSize + 1, 32) },
                onDecreaseFontSize: { appState.fontSize = max(appState.fontSize - 1, 10) }
            )
        )
    }
    
    // MARK: - Main Content
    private var mainContent: some View {
        VStack(spacing: 0) {
            if !appState.zenMode {
                TabBarView(
                    tabs: appState.sortedTabs,
                    selectedId: appState.selectedTabId,
                    theme: appState.theme,
                    onSelect: { appState.selectTab($0) },
                    onClose: { confirmClose($0) },
                    onPin: { appState.togglePin($0) },
                    onNewTab: { appState.newTab() },
                    onToggleSidebar: { withAnimation { appState.showSidebar.toggle() } }
                )
                
                if appState.showFind {
                    FindBarView(findText: $findText, replaceText: $replaceText) {
                        withAnimation { appState.showFind = false }
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            
            HStack(spacing: 0) {
                if appState.showSidebar && !appState.zenMode {
                    SidebarView(
                        folderURL: appState.folderURL,
                        onSelect: { openFile($0) },
                        onOpenFolder: { openFolder() }
                    )
                    .frame(width: 220)
                    .transition(.move(edge: .leading))
                }
                
                editorAndPreview
            }
            
            if !appState.zenMode {
                StatusBarView(
                    wordCount: appState.wordCount,
                    lineCount: appState.lineCount,
                    theme: appState.theme
                )
            }
        }
    }
    
    private var editorAndPreview: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                if let idx = appState.selectedIndex {
                    EditorView(
                        text: Binding(
                            get: { appState.tabs[idx].content },
                            set: { appState.updateContent($0) }
                        ),
                        fontSize: appState.fontSize,
                        theme: appState.theme
                    )
                    .frame(width: appState.showPreview && !appState.zenMode ? geo.size.width * splitRatio : nil)
                    
                    if appState.showPreview && !appState.zenMode {
                        DraggableDivider(ratio: $splitRatio, theme: appState.theme)
                        PreviewView(
                            markdown: appState.tabs[idx].content,
                            theme: appState.theme
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Overlays
    @ViewBuilder
    private var overlays: some View {
        if appState.showCommandPalette {
            CommandPaletteView(
                isPresented: $appState.showCommandPalette,
                theme: appState.theme,
                actions: commandActions
            )
        }
    }
    
    private var commandActions: [(String, String, () -> Void)] {
        [
            ("New Tab", "⌘T", { appState.newTab() }),
            ("Open File", "⌘O", { openFiles() }),
            ("Save", "⌘S", { saveCurrentTab() }),
            ("Toggle Preview", "⌘P", { appState.showPreview.toggle() }),
            ("Toggle Sidebar", "⌘B", { withAnimation { appState.showSidebar.toggle() } }),
            ("Find", "⌘F", { appState.showFind = true }),
            ("Zen Mode", "⌘⇧Z", { withAnimation { appState.zenMode.toggle() } }),
            ("Increase Font", "⌘+", { appState.fontSize = min(appState.fontSize + 1, 32) }),
            ("Decrease Font", "⌘-", { appState.fontSize = max(appState.fontSize - 1, 10) }),
            ("Theme: Dracula", "", { appState.theme = .dracula }),
            ("Theme: Monokai", "", { appState.theme = .monokai }),
            ("Theme: One Dark", "", { appState.theme = .oneDark }),
            ("Theme: GitHub Dark", "", { appState.theme = .github }),
            ("Export HTML", "", { exportHTML() }),
            ("Export PDF", "", { exportPDF() }),
        ]
    }
    
    // MARK: - Actions
    private func confirmClose(_ tab: Tab? = nil) {
        let targetTab = tab ?? appState.selectedTab
        guard let t = targetTab else { return }
        if t.isModified {
            tabToClose = t
            showCloseAlert = true
        } else {
            appState.closeTab(t)
        }
    }
    
    private func forceClose() {
        guard let tab = tabToClose else { return }
        appState.closeTab(tab)
        tabToClose = nil
    }
    
    private func saveAndClose() {
        guard let tab = tabToClose, let idx = appState.tabs.firstIndex(of: tab) else { return }
        if let url = appState.tabs[idx].fileURL {
            _ = FileService.shared.save(content: appState.tabs[idx].content, to: url)
        }
        forceClose()
    }
    
    private func saveCurrentTab() {
        guard let idx = appState.selectedIndex else { return }
        if let url = appState.tabs[idx].fileURL {
            if FileService.shared.save(content: appState.tabs[idx].content, to: url) {
                appState.tabs[idx].isModified = false
            }
        } else {
            if let url = FileService.shared.saveAs(content: appState.tabs[idx].content, suggestedName: appState.tabs[idx].name) {
                appState.tabs[idx].fileURL = url
                appState.tabs[idx].name = url.lastPathComponent
                appState.tabs[idx].isModified = false
            }
        }
    }
    
    private func openFiles() {
        for url in FileService.shared.openFiles() {
            openFile(url)
        }
    }
    
    private func openFile(_ url: URL) {
        if let existing = appState.tabs.first(where: { $0.fileURL == url }) {
            appState.selectedTabId = existing.id
            return
        }
        guard let content = FileService.shared.loadContent(from: url) else { return }
        let tab = Tab(name: url.lastPathComponent, content: content, filePath: url.path)
        appState.tabs.append(tab)
        appState.selectedTabId = tab.id
    }
    
    private func openFolder() {
        guard let url = FileService.shared.openFolder() else { return }
        appState.folderURL = url
        withAnimation { appState.showSidebar = true }
    }
    
    private func exportHTML() {
        guard let tab = appState.selectedTab else { return }
        FileService.shared.exportHTML(content: tab.content, name: tab.name)
    }
    
    private func exportPDF() {
        guard let tab = appState.selectedTab else { return }
        FileService.shared.exportPDF(content: tab.content, name: tab.name)
    }
}

// MARK: - Draggable Divider
struct DraggableDivider: View {
    @Binding var ratio: CGFloat
    let theme: Theme
    @State private var isDragging = false
    @State private var isHovering = false
    
    var body: some View {
        Rectangle()
            .fill(Color(hex: theme.accent).opacity(isDragging || isHovering ? 0.8 : 0))
            .frame(width: isDragging || isHovering ? 4 : 1)
            .overlay(
                Rectangle()
                    .fill(Color(hex: theme.comment).opacity(isDragging || isHovering ? 0 : 1))
                    .frame(width: 1)
            )
            .overlay(
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: 8)
                    .contentShape(Rectangle())
                    .cursor(.resizeLeftRight)
                    .onHover { hovering in
                        withAnimation(.easeInOut(duration: 0.15)) {
                            isHovering = hovering
                        }
                    }
            )
            .animation(.easeInOut(duration: 0.15), value: isDragging)
            .animation(.easeInOut(duration: 0.15), value: isHovering)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        isDragging = true
                        if let window = NSApp.keyWindow {
                            let totalWidth = window.contentView?.bounds.width ?? 800
                            let newRatio = (ratio * totalWidth + value.translation.width) / totalWidth
                            ratio = min(max(newRatio, 0.2), 0.8)
                        }
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )
    }
}

extension View {
    func cursor(_ cursor: NSCursor) -> some View {
        self.onHover { inside in
            if inside { cursor.push() } else { NSCursor.pop() }
        }
    }
}
