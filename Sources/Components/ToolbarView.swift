// Toolbar View
import SwiftUI

struct ToolbarView: ToolbarContent {
    @ObservedObject var appState: AppState
    
    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .navigation) {
            Menu {
                Button("New Tab ⌘T", action: appState.newTab)
                Button("Open File ⌘O", action: openFiles)
                Button("Open Folder", action: openFolder)
                Divider()
                Button("Save As...", action: saveAs)
                Button("Export HTML", action: exportHTML)
                Button("Export PDF", action: exportPDF)
            } label: { Image(systemName: "doc.badge.plus") }.help("File Menu")
            
            Button { withAnimation { appState.showPreview.toggle() } } label: {
                Image(systemName: appState.showPreview ? "rectangle.righthalf.filled" : "rectangle.fill")
            }.help("Toggle Preview (⌘P)")
            
            Menu {
                ForEach(Theme.all, id: \.name) { t in Button(t.name) { appState.theme = t } }
            } label: { Image(systemName: "paintpalette") }.help("Change Theme")
        }
        
        ToolbarItemGroup {
            if appState.isFullscreen {
                Button { NSApp.windows.first?.toggleFullScreen(nil) } label: {
                    Image(systemName: "arrow.down.right.and.arrow.up.left")
                }.help("Exit Fullscreen")
            }
            Button { appState.showCommandPalette = true } label: { Image(systemName: "command") }.help("Command Palette (⇧⌘P)")
            Button { appState.showFind.toggle() } label: { Image(systemName: "magnifyingglass") }.help("Find (⌘F)")
            Button(action: save) { Image(systemName: "square.and.arrow.down") }.help("Save (⌘S)")
        }
    }
    
    private func openFiles() {
        FileService.shared.openFiles().forEach { url in
            guard let content = FileService.shared.loadContent(from: url) else { return }
            appState.tabs.append(Tab(name: url.lastPathComponent, content: content, filePath: url.path))
            appState.selectedTabId = appState.tabs.last?.id
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
            if FileService.shared.save(content: appState.tabs[idx].content, to: url) { appState.tabs[idx].isModified = false }
        } else { saveAs() }
    }
    
    private func saveAs() {
        guard let idx = appState.selectedIndex,
              let url = FileService.shared.saveAs(content: appState.tabs[idx].content, suggestedName: appState.tabs[idx].name) else { return }
        appState.tabs[idx].fileURL = url
        appState.tabs[idx].name = url.lastPathComponent
        appState.tabs[idx].isModified = false
    }
    
    private func exportHTML() { guard let t = appState.selectedTab else { return }; FileService.shared.exportHTML(content: t.content, name: t.name) }
    private func exportPDF() { guard let t = appState.selectedTab else { return }; FileService.shared.exportPDF(content: t.content, name: t.name) }
}
