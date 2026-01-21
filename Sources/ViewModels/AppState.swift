// App State - Global Observable State
import SwiftUI

final class AppState: ObservableObject {
    @Published var tabs: [Tab] = []
    @Published var selectedTabId: UUID?
    @Published var theme: Theme = .dracula
    @Published var fontSize: CGFloat = 14
    @Published var showPreview = true
    @Published var showSidebar = false
    @Published var showFind = false
    @Published var showCommandPalette = false
    @Published var zenMode = false
    @Published var isFullscreen = false
    @Published var folderURL: URL?
    @Published var tabToClose: Tab?
    @Published var showCloseAlert = false
    
    var selectedIndex: Int? { tabs.firstIndex { $0.id == selectedTabId } }
    var selectedTab: Tab? { selectedIndex.map { tabs[$0] } }
    var wordCount: Int { selectedTab?.content.split { $0.isWhitespace || $0.isNewline }.count ?? 0 }
    var lineCount: Int { selectedTab?.content.components(separatedBy: "\n").count ?? 0 }
    var sortedTabs: [Tab] { tabs.sorted { $0.isPinned && !$1.isPinned } }
    
    private let stateKey = "appState"
    private var autoSaveTimer: Timer?
    
    init() {
        loadState()
        if tabs.isEmpty { tabs = [Tab.welcome()]; selectedTabId = tabs.first?.id }
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in self?.autoSave() }
    }
    
    func newTab() { let tab = Tab.untitled(); tabs.append(tab); selectedTabId = tab.id }
    
    func closeTab(_ tab: Tab) {
        guard let idx = tabs.firstIndex(of: tab) else { return }
        tabs.remove(at: idx)
        if selectedTabId == tab.id { selectedTabId = tabs.indices.contains(idx) ? tabs[idx].id : tabs.last?.id }
        if tabs.isEmpty { newTab() }
    }
    
    func togglePin(_ tab: Tab) { if let idx = tabs.firstIndex(of: tab) { tabs[idx].isPinned.toggle() } }
    func updateContent(_ content: String) { if let idx = selectedIndex { tabs[idx].content = content; tabs[idx].isModified = true } }
    func selectTab(_ tab: Tab) { selectedTabId = tab.id }
    func adjustFontSize(by delta: CGFloat) { fontSize = min(max(fontSize + delta, 10), 32) }
    
    func requestCloseTab(_ tab: Tab? = nil) {
        let target = tab ?? selectedTab
        guard let t = target else { return }
        if t.isModified { tabToClose = t; showCloseAlert = true } else { closeTab(t) }
    }
    
    func forceCloseTab() {
        guard let tab = tabToClose else { return }
        closeTab(tab); tabToClose = nil
    }
    
    func saveAndCloseTab() {
        guard let tab = tabToClose, let idx = tabs.firstIndex(of: tab) else { return }
        if let url = tabs[idx].fileURL {
            _ = FileService.shared.save(content: tabs[idx].content, to: url)
        } else if let url = FileService.shared.saveAs(content: tabs[idx].content, suggestedName: tabs[idx].name) {
            tabs[idx].fileURL = url
        }
        forceCloseTab()
    }
    
    func saveState() {
        guard let data = try? JSONEncoder().encode(SavedState(tabs: tabs, selectedTabId: selectedTabId, fontSize: fontSize, themeName: theme.name)) else { return }
        UserDefaults.standard.set(data, forKey: stateKey)
    }
    
    func loadState() {
        guard let data = UserDefaults.standard.data(forKey: stateKey),
              let state = try? JSONDecoder().decode(SavedState.self, from: data) else { return }
        tabs = state.tabs
        selectedTabId = state.selectedTabId ?? tabs.first?.id
        fontSize = state.fontSize
        theme = Theme.all.first { $0.name == state.themeName } ?? .dracula
    }
    
    private func autoSave() {
        for i in tabs.indices {
            guard tabs[i].isModified, let url = tabs[i].fileURL else { continue }
            try? tabs[i].content.write(to: url, atomically: true, encoding: .utf8)
            tabs[i].isModified = false
        }
    }
}

private struct SavedState: Codable {
    let tabs: [Tab], selectedTabId: UUID?, fontSize: CGFloat, themeName: String
}
