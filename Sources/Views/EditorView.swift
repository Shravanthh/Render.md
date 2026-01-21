// Editor View - Syntax Highlighted Text Editor
import SwiftUI
import AppKit

struct EditorView: NSViewRepresentable {
    @Binding var text: String
    @Binding var scrollPercent: CGFloat
    var fontSize: CGFloat
    var theme: Theme
    var syncEnabled: Bool
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        let textView = SyntaxTextView()
        
        configureTextView(textView)
        textView.delegate = context.coordinator
        textView.string = text
        
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
        scrollView.contentView.postsBoundsChangedNotifications = true
        
        NotificationCenter.default.addObserver(context.coordinator, selector: #selector(Coordinator.scrollViewDidScroll(_:)),
                                               name: NSView.boundsDidChangeNotification, object: scrollView.contentView)
        
        DispatchQueue.main.async { textView.applyHighlighting() }
        return scrollView
    }
    
    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? SyntaxTextView else { return }
        
        context.coordinator.parent = self
        
        textView.theme = theme
        textView.backgroundColor = NSColor(Color(hex: theme.editorBg))
        textView.font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        
        if textView.string != text {
            let selection = textView.selectedRanges
            textView.string = text
            textView.selectedRanges = selection
            textView.applyHighlighting()
        }
        
        // Sync scroll from preview (only if not currently scrolling editor)
        if syncEnabled && !context.coordinator.isScrolling {
            let maxScroll = max(1, (scrollView.documentView?.frame.height ?? 0) - scrollView.contentView.bounds.height)
            let currentPercent = scrollView.contentView.bounds.origin.y / maxScroll
            if abs(currentPercent - scrollPercent) > 0.01 {
                let targetY = maxScroll * scrollPercent
                scrollView.contentView.scroll(to: NSPoint(x: 0, y: targetY))
            }
        }
    }
    
    private func configureTextView(_ textView: SyntaxTextView) {
        textView.theme = theme
        textView.backgroundColor = NSColor(Color(hex: theme.editorBg))
        textView.textColor = NSColor(Color(hex: theme.text))
        textView.font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        textView.insertionPointColor = NSColor(Color(hex: theme.text))
        textView.selectedTextAttributes = [.backgroundColor: NSColor(Color(hex: theme.accent).opacity(0.3))]
        textView.isRichText = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.allowsUndo = true
        textView.autoresizingMask = [.width]
        textView.isVerticallyResizable = true
        textView.textContainer?.widthTracksTextView = true
        textView.textContainerInset = NSSize(width: 50, height: 16)
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 6
        textView.defaultParagraphStyle = paragraphStyle
    }
    
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: EditorView
        var isScrolling = false
        
        init(_ parent: EditorView) { self.parent = parent }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? SyntaxTextView else { return }
            parent.text = textView.string
            textView.applyHighlighting()
        }
        
        @objc func scrollViewDidScroll(_ notification: Notification) {
            guard parent.syncEnabled,
                  let clipView = notification.object as? NSClipView,
                  let scrollView = clipView.superview as? NSScrollView,
                  let documentView = scrollView.documentView else { return }
            
            isScrolling = true
            let maxScroll = max(1, documentView.frame.height - clipView.bounds.height)
            let percent = clipView.bounds.origin.y / maxScroll
            let newPercent = min(max(percent, 0), 1)
            
            // Only update if change is significant
            if abs(newPercent - parent.scrollPercent) > 0.005 {
                parent.scrollPercent = newPercent
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.isScrolling = false
            }
        }
    }
}

// MARK: - Syntax Highlighted Text View
class SyntaxTextView: NSTextView {
    var theme = Theme.dracula
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        drawLineNumbers()
        drawCurrentLineHighlight()
    }
    
    private func drawCurrentLineHighlight() {
        guard let lm = layoutManager, let tc = textContainer else { return }
        let insertionPoint = selectedRange().location
        let lineRange = (string as NSString).lineRange(for: NSRange(location: insertionPoint, length: 0))
        let glyphRange = lm.glyphRange(forCharacterRange: lineRange, actualCharacterRange: nil)
        var rect = lm.boundingRect(forGlyphRange: glyphRange, in: tc)
        rect.origin.x = 0
        rect.origin.y += textContainerInset.height
        rect.size.width = bounds.width
        NSColor(Color(hex: theme.accent).opacity(0.08)).setFill()
        NSBezierPath(rect: rect).fill()
    }
    
    private func drawLineNumbers() {
        guard let lm = layoutManager, let tc = textContainer else { return }
        let visibleRect = enclosingScrollView?.contentView.bounds ?? bounds
        let glyphRange = lm.glyphRange(forBoundingRect: visibleRect, in: tc)
        let charRange = lm.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)
        
        let content = string as NSString
        var lineNum = content.substring(to: min(charRange.location, content.length)).components(separatedBy: "\n").count
        
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .regular),
            .foregroundColor: NSColor(Color(hex: theme.comment))
        ]
        
        var idx = charRange.location
        while idx < min(charRange.location + charRange.length, content.length) {
            let lineRange = content.lineRange(for: NSRange(location: idx, length: 0))
            let glyphIdx = lm.glyphIndexForCharacter(at: lineRange.location)
            var rect = lm.lineFragmentRect(forGlyphAt: glyphIdx, effectiveRange: nil)
            rect.origin.y += textContainerInset.height
            
            let numStr = "\(lineNum)" as NSString
            let size = numStr.size(withAttributes: attrs)
            numStr.draw(at: NSPoint(x: 35 - size.width, y: rect.origin.y), withAttributes: attrs)
            
            lineNum += 1
            idx = NSMaxRange(lineRange)
        }
    }
    
    func applyHighlighting() {
        guard let ts = textStorage else { return }
        let fullRange = NSRange(location: 0, length: ts.length)
        
        ts.beginEditing()
        ts.addAttribute(.foregroundColor, value: NSColor(Color(hex: theme.text)), range: fullRange)
        
        let patterns: [(String, String)] = [
            ("^#{1,6} .+$", theme.heading),
            ("\\*\\*[^*]+\\*\\*", theme.keyword),
            ("\\*[^*]+\\*", theme.string),
            ("`[^`]+`", theme.accent),
            ("```[\\s\\S]*?```", theme.accent),
            ("\\[.+?\\]\\(.+?\\)", theme.keyword),
            ("^>.*$", theme.comment),
            ("^- .+$", theme.string),
            ("^\\d+\\. .+$", theme.string),
        ]
        
        for (pattern, color) in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines]) else { continue }
            for match in regex.matches(in: string, range: fullRange) {
                ts.addAttribute(.foregroundColor, value: NSColor(Color(hex: color)), range: match.range)
            }
        }
        ts.endEditing()
    }
}
