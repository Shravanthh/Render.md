// App Delegate for macOS window configuration
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        configureWindow()
    }
    
    func applicationDidBecomeActive(_ notification: Notification) {
        configureWindow()
    }
    
    private func configureWindow() {
        DispatchQueue.main.async {
            guard let window = NSApplication.shared.windows.first else { return }
            window.styleMask.insert([.miniaturizable, .resizable, .closable])
            window.collectionBehavior = [.fullScreenPrimary, .managed]
            window.isReleasedWhenClosed = false
        }
    }
}
