// Main Content View
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var findText = ""
    @State private var replaceText = ""
    @State private var splitRatio: CGFloat = 0.5
    
    var body: some View {
        ZStack {
            mainContent
            if appState.showCommandPalette {
                CommandPaletteView(isPresented: $appState.showCommandPalette, theme: appState.theme, actions: commandActions)
            }
        }
        .toolbar { ToolbarView(appState: appState) }
        .navigationTitle(appState.selectedTab?.name ?? "Render.md")
        .preferredColorScheme(.dark)
        .frame(minWidth: 800, minHeight: 600)
        .background(Color(hex: appState.theme.bg))
        .onAppear { appState.loadState() }
        .onDisappear { appState.saveState() }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didEnterFullScreenNotification)) { _ in appState.isFullscreen = true }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didExitFullScreenNotification)) { _ in appState.isFullscreen = false }
        .alert("Unsaved Changes", isPresented: $appState.showCloseAlert) {
            Button("Save") { appState.saveAndCloseTab() }
            Button("Don't Save", role: .destructive) { appState.forceCloseTab() }
            Button("Cancel", role: .cancel) { appState.tabToClose = nil }
        } message: { Text("Save changes to \"\(appState.tabToClose?.name ?? "")\"?") }
        .background(KeyboardHandler(
            onNewTab: appState.newTab,
            onCloseTab: { appState.requestCloseTab() },
            onSave: saveCurrentTab,
            onFind: { appState.showFind.toggle() },
            onTogglePreview: { appState.showPreview.toggle() },
            onCommandPalette: { appState.showCommandPalette = true },
            onZenMode: { withAnimation { appState.zenMode.toggle() } },
            onIncreaseFontSize: { appState.adjustFontSize(by: 1) },
            onDecreaseFontSize: { appState.adjustFontSize(by: -1) }
        ))
    }
    
    private var mainContent: some View {
        VStack(spacing: 0) {
            if !appState.zenMode {
                TabBarView(
                    tabs: appState.sortedTabs, selectedId: appState.selectedTabId, theme: appState.theme,
                    onSelect: appState.selectTab, onClose: { appState.requestCloseTab($0) }, onPin: appState.togglePin,
                    onNewTab: appState.newTab, onToggleSidebar: { withAnimation { appState.showSidebar.toggle() } }
                )
                if appState.showFind {
                    FindBarView(findText: $findText, replaceText: $replaceText) { withAnimation { appState.showFind = false } }
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            HStack(spacing: 0) {
                if appState.showSidebar && !appState.zenMode {
                    SidebarView(folderURL: appState.folderURL, onSelect: openFile, onOpenFolder: openFolder)
                        .frame(width: 220)
                        .transition(.move(edge: .leading))
                }
                editorAndPreview
            }
            if !appState.zenMode {
                StatusBarView(wordCount: appState.wordCount, lineCount: appState.lineCount, theme: appState.theme)
            }
        }
    }
    
    private var editorAndPreview: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                if let idx = appState.selectedIndex {
                    EditorView(
                        text: Binding(get: { appState.tabs[idx].content }, set: appState.updateContent),
                        fontSize: appState.fontSize, theme: appState.theme
                    )
                    .frame(width: appState.showPreview && !appState.zenMode ? geo.size.width * splitRatio : nil)
                    
                    if appState.showPreview && !appState.zenMode {
                        DraggableDivider(ratio: $splitRatio, theme: appState.theme)
                        PreviewView(markdown: appState.tabs[idx].content, theme: appState.theme)
                    }
                }
            }
        }
    }
    
    private var commandActions: [(String, String, () -> Void)] {
        [
            ("New Tab", "⌘T", appState.newTab),
            ("Close Tab", "⌘W", { appState.requestCloseTab() }),
            ("Open File", "⌘O", openFiles),
            ("Save", "⌘S", saveCurrentTab),
            ("Toggle Preview", "⌘P", { appState.showPreview.toggle() }),
            ("Toggle Sidebar", "⌘B", { withAnimation { appState.showSidebar.toggle() } }),
            ("Find", "⌘F", { appState.showFind = true }),
            ("Zen Mode", "⌘⇧Z", { withAnimation { appState.zenMode.toggle() } }),
            ("Increase Font", "⌘+", { appState.adjustFontSize(by: 1) }),
            ("Decrease Font", "⌘-", { appState.adjustFontSize(by: -1) }),
        ] + Theme.all.map { t in ("Theme: \(t.name)", "", { appState.theme = t }) }
          + [("Export HTML", "", exportHTML), ("Export PDF", "", exportPDF)]
    }
    
    // MARK: - Actions
    private func saveCurrentTab() {
        guard let idx = appState.selectedIndex else { return }
        if let url = appState.tabs[idx].fileURL {
            if FileService.shared.save(content: appState.tabs[idx].content, to: url) { appState.tabs[idx].isModified = false }
        } else if let url = FileService.shared.saveAs(content: appState.tabs[idx].content, suggestedName: appState.tabs[idx].name) {
            appState.tabs[idx].fileURL = url
            appState.tabs[idx].name = url.lastPathComponent
            appState.tabs[idx].isModified = false
        }
    }
    
    private func openFiles() { FileService.shared.openFiles().forEach(openFile) }
    
    private func openFile(_ url: URL) {
        if let existing = appState.tabs.first(where: { $0.fileURL == url }) { appState.selectedTabId = existing.id; return }
        guard let content = FileService.shared.loadContent(from: url) else { return }
        appState.tabs.append(Tab(name: url.lastPathComponent, content: content, filePath: url.path))
        appState.selectedTabId = appState.tabs.last?.id
    }
    
    private func openFolder() {
        guard let url = FileService.shared.openFolder() else { return }
        appState.folderURL = url
        withAnimation { appState.showSidebar = true }
    }
    
    private func exportHTML() { guard let tab = appState.selectedTab else { return }; FileService.shared.exportHTML(content: tab.content, name: tab.name) }
    private func exportPDF() { guard let tab = appState.selectedTab else { return }; FileService.shared.exportPDF(content: tab.content, name: tab.name) }
}

// MARK: - Draggable Divider
struct DraggableDivider: View {
    @Binding var ratio: CGFloat
    let theme: Theme
    @State private var isActive = false
    
    var body: some View {
        Rectangle()
            .fill(Color(hex: isActive ? theme.accent : theme.comment).opacity(isActive ? 0.8 : 1))
            .frame(width: isActive ? 4 : 1)
            .animation(.easeInOut(duration: 0.15), value: isActive)
            .contentShape(Rectangle().inset(by: -4))
            .onHover { isActive = $0 }
            .gesture(DragGesture().onChanged { v in
                isActive = true
                if let w = NSApp.keyWindow?.contentView?.bounds.width {
                    ratio = min(max((ratio * w + v.translation.width) / w, 0.2), 0.8)
                }
            }.onEnded { _ in isActive = false })
            .onHover { if $0 { NSCursor.resizeLeftRight.push() } else { NSCursor.pop() } }
    }
}
