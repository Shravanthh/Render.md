// Toolbar View
import SwiftUI

struct ToolbarView: ToolbarContent {
    @ObservedObject var appState: AppState
    
    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .navigation) {
            fileMenu
            previewToggle
            themeMenu
        }
        
        ToolbarItemGroup {
            if appState.isFullscreen {
                exitFullscreenButton
            }
            commandPaletteButton
            findButton
            saveButton
        }
    }
    
    // MARK: - Navigation Items
    private var fileMenu: some View {
        Menu {
            Button("New Tab ⌘T") { appState.newTab() }
            Button("Open File ⌘O") { openFiles() }
            Button("Open Folder") { openFolder() }
            Divider()
            Button("Save As...") { saveAs() }
            Button("Export HTML") { exportHTML() }
            Button("Export PDF") { exportPDF() }
        } label: {
            Image(systemName: "doc.badge.plus")
        }
        .help("File Menu")
    }
    
    private var previewToggle: some View {
        Button {
            withAnimation { appState.showPreview.toggle() }
        } label: {
            Image(systemName: appState.showPreview ? "rectangle.righthalf.filled" : "rectangle.fill")
        }
        .help("Toggle Preview (⌘P)")
    }
    
    private var themeMenu: some View {
        Menu {
            ForEach(Theme.all, id: \.name) { theme in
                Button(theme.name) { appState.theme = theme }
            }
        } label: {
            Image(systemName: "paintpalette")
        }
        .help("Change Theme")
    }
    
    // MARK: - Trailing Items
    private var exitFullscreenButton: some View {
        Button { toggleFullscreen() } label: {
            Image(systemName: "arrow.down.right.and.arrow.up.left")
        }
        .help("Exit Fullscreen")
    }
    
    private var commandPaletteButton: some View {
        Button { appState.showCommandPalette = true } label: {
            Image(systemName: "command")
        }
        .help("Command Palette (⇧⌘P)")
    }
    
    private var findButton: some View {
        Button { appState.showFind.toggle() } label: {
            Image(systemName: "magnifyingglass")
        }
        .help("Find (⌘F)")
    }
    
    private var saveButton: some View {
        Button { save() } label: {
            Image(systemName: "square.and.arrow.down")
        }
        .help("Save (⌘S)")
    }
    
    // MARK: - Actions
    private func openFiles() {
        for url in FileService.shared.openFiles() {
            guard let content = FileService.shared.loadContent(from: url) else { continue }
            let tab = Tab(name: url.lastPathComponent, content: content, filePath: url.path)
            appState.tabs.append(tab)
            appState.selectedTabId = tab.id
        }
    }
    
    private func openFolder() {
        guard let url = FileService.shared.openFolder() else { return }
        appState.folderURL = url
        withAnimation { appState.showSidebar = true }
    }
    
    private func save() {
        guard let idx = appState.selectedIndex else { return }
        if let url = appState.tabs[idx].fileURL {
            if FileService.shared.save(content: appState.tabs[idx].content, to: url) {
                appState.tabs[idx].isModified = false
            }
        } else {
            saveAs()
        }
    }
    
    private func saveAs() {
        guard let idx = appState.selectedIndex else { return }
        if let url = FileService.shared.saveAs(content: appState.tabs[idx].content, suggestedName: appState.tabs[idx].name) {
            appState.tabs[idx].fileURL = url
            appState.tabs[idx].name = url.lastPathComponent
            appState.tabs[idx].isModified = false
        }
    }
    
    private func exportHTML() {
        guard let tab = appState.selectedTab else { return }
        FileService.shared.exportHTML(content: tab.content, name: tab.name)
    }
    
    private func exportPDF() {
        guard let tab = appState.selectedTab else { return }
        FileService.shared.exportPDF(content: tab.content, name: tab.name)
    }
    
    private func toggleFullscreen() {
        NSApplication.shared.windows.first?.toggleFullScreen(nil)
    }
}
