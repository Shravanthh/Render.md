// App State - Global Observable State
import SwiftUI
import Combine

final class AppState: ObservableObject {
    // MARK: - Published Properties
    @Published var tabs: [Tab] = []
    @Published var selectedTabId: UUID?
    @Published var theme: Theme = .dracula
    @Published var fontSize: CGFloat = 14
    @Published var showPreview = true
    @Published var showSidebar = false
    @Published var showFind = false
    @Published var showCommandPalette = false
    @Published var showGoToLine = false
    @Published var zenMode = false
    @Published var isFullscreen = false
    @Published var folderURL: URL?
    
    // MARK: - Computed Properties
    var selectedIndex: Int? {
        tabs.firstIndex { $0.id == selectedTabId }
    }
    
    var selectedTab: Tab? {
        guard let idx = selectedIndex else { return nil }
        return tabs[idx]
    }
    
    var wordCount: Int {
        selectedTab?.content.split { $0.isWhitespace || $0.isNewline }.count ?? 0
    }
    
    var lineCount: Int {
        selectedTab?.content.components(separatedBy: "\n").count ?? 0
    }
    
    var sortedTabs: [Tab] {
        tabs.sorted { ($0.isPinned ? 0 : 1) < ($1.isPinned ? 0 : 1) }
    }
    
    // MARK: - Initialization
    init() {
        loadState()
        if tabs.isEmpty {
            tabs = [Tab.welcome()]
            selectedTabId = tabs.first?.id
        }
        setupAutoSave()
    }
    
    // MARK: - Tab Management
    func newTab() {
        let tab = Tab.untitled()
        tabs.append(tab)
        selectedTabId = tab.id
    }
    
    func closeTab(_ tab: Tab) {
        guard let idx = tabs.firstIndex(of: tab) else { return }
        tabs.remove(at: idx)
        if selectedTabId == tab.id {
            selectedTabId = tabs.indices.contains(idx) ? tabs[idx].id : tabs.last?.id
        }
        if tabs.isEmpty { newTab() }
    }
    
    func togglePin(_ tab: Tab) {
        guard let idx = tabs.firstIndex(of: tab) else { return }
        tabs[idx].isPinned.toggle()
    }
    
    func updateContent(_ content: String) {
        guard let idx = selectedIndex else { return }
        tabs[idx].content = content
        tabs[idx].isModified = true
    }
    
    func selectTab(_ tab: Tab) {
        selectedTabId = tab.id
    }
    
    // MARK: - Persistence
    private let stateKey = "appState"
    private let backupKey = "crashBackup"
    
    func saveState() {
        let data = SavedState(tabs: tabs, selectedTabId: selectedTabId, fontSize: fontSize, themeName: theme.name)
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: stateKey)
        }
    }
    
    func loadState() {
        // Try crash backup first
        if let backupData = UserDefaults.standard.data(forKey: backupKey),
           let backup = try? JSONDecoder().decode([Tab].self, from: backupData),
           !backup.isEmpty {
            tabs = backup
            selectedTabId = tabs.first?.id
            UserDefaults.standard.removeObject(forKey: backupKey)
            return
        }
        
        // Load saved state
        guard let data = UserDefaults.standard.data(forKey: stateKey),
              let state = try? JSONDecoder().decode(SavedState.self, from: data) else { return }
        
        tabs = state.tabs
        selectedTabId = state.selectedTabId ?? tabs.first?.id
        fontSize = state.fontSize
        theme = Theme.all.first { $0.name == state.themeName } ?? .dracula
    }
    
    func saveBackup() {
        if let encoded = try? JSONEncoder().encode(tabs) {
            UserDefaults.standard.set(encoded, forKey: backupKey)
        }
    }
    
    private func setupAutoSave() {
        Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.autoSaveModifiedTabs()
        }
    }
    
    private func autoSaveModifiedTabs() {
        for i in tabs.indices where tabs[i].isModified && tabs[i].fileURL != nil {
            try? tabs[i].content.write(to: tabs[i].fileURL!, atomically: true, encoding: .utf8)
            tabs[i].isModified = false
        }
    }
}

// MARK: - Saved State
private struct SavedState: Codable {
    let tabs: [Tab]
    let selectedTabId: UUID?
    let fontSize: CGFloat
    let themeName: String
}
