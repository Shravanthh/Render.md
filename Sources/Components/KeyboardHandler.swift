// Keyboard Handler
import SwiftUI
import AppKit

struct KeyboardHandler: NSViewRepresentable {
    var onNewTab: () -> Void
    var onCloseTab: () -> Void
    var onSave: () -> Void
    var onFind: () -> Void
    var onTogglePreview: () -> Void
    var onCommandPalette: () -> Void
    var onZenMode: () -> Void
    var onIncreaseFontSize: () -> Void
    var onDecreaseFontSize: () -> Void
    
    func makeNSView(context: Context) -> KeyboardView {
        let view = KeyboardView()
        view.handler = self
        return view
    }
    
    func updateNSView(_ view: KeyboardView, context: Context) {
        view.handler = self
    }
}

class KeyboardView: NSView {
    var handler: KeyboardHandler?
    
    override var acceptsFirstResponder: Bool { true }
    
    override func keyDown(with event: NSEvent) {
        let cmd = event.modifierFlags.contains(.command)
        let shift = event.modifierFlags.contains(.shift)
        
        guard cmd, let key = event.charactersIgnoringModifiers else {
            super.keyDown(with: event)
            return
        }
        
        switch (key, shift) {
        case ("t", false): handler?.onNewTab()
        case ("w", false): handler?.onCloseTab()
        case ("s", false): handler?.onSave()
        case ("f", false): handler?.onFind()
        case ("p", false): handler?.onTogglePreview()
        case ("p", true): handler?.onCommandPalette()
        case ("z", true): handler?.onZenMode()
        case ("=", _), ("+", _): handler?.onIncreaseFontSize()
        case ("-", false): handler?.onDecreaseFontSize()
        default: super.keyDown(with: event)
        }
    }
}
