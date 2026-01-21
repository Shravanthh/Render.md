// App Entry Point
import SwiftUI

@main
struct RenderMDApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Tab") { appState.newTab() }.keyboardShortcut("t")
                Button("Close Tab") { appState.requestCloseTab() }.keyboardShortcut("w")
            }
            CommandGroup(replacing: .saveItem) {
                Button("Save") { saveCurrentTab() }.keyboardShortcut("s")
            }
            CommandGroup(after: .sidebar) {
                Button("Toggle Preview") { appState.showPreview.toggle() }.keyboardShortcut("p")
                Button("Toggle Sidebar") { appState.showSidebar.toggle() }.keyboardShortcut("b")
                Button("Find") { appState.showFind.toggle() }.keyboardShortcut("f")
                Divider()
                Button("Zen Mode") { appState.zenMode.toggle() }.keyboardShortcut("z", modifiers: [.command, .shift])
                Button("Command Palette") { appState.showCommandPalette = true }.keyboardShortcut("p", modifiers: [.command, .shift])
            }
            CommandGroup(after: .toolbar) {
                Button("Increase Font Size") { appState.adjustFontSize(by: 1) }.keyboardShortcut("+", modifiers: .command)
                Button("Decrease Font Size") { appState.adjustFontSize(by: -1) }.keyboardShortcut("-", modifiers: .command)
            }
        }
    }
    
    private func saveCurrentTab() {
        guard let idx = appState.selectedIndex else { return }
        if let url = appState.tabs[idx].fileURL {
            if FileService.shared.save(content: appState.tabs[idx].content, to: url) {
                appState.tabs[idx].isModified = false
            }
        } else if let url = FileService.shared.saveAs(content: appState.tabs[idx].content, suggestedName: appState.tabs[idx].name) {
            appState.tabs[idx].fileURL = url
            appState.tabs[idx].name = url.lastPathComponent
            appState.tabs[idx].isModified = false
        }
    }
}
