// Preview View - Rendered Markdown
import SwiftUI
import Markdown

struct PreviewView: NSViewRepresentable {
    let markdown: String
    let theme: Theme
    @Binding var scrollPercent: CGFloat
    var syncEnabled: Bool
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        let textView = NSTextView()
        
        textView.isEditable = false
        textView.isSelectable = true
        textView.drawsBackground = false
        textView.textContainerInset = NSSize(width: 20, height: 20)
        textView.autoresizingMask = [.width]
        textView.isVerticallyResizable = true
        textView.textContainer?.widthTracksTextView = true
        
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = true
        scrollView.backgroundColor = NSColor(Color(hex: theme.editorBg))
        
        return scrollView
    }
    
    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        
        scrollView.backgroundColor = NSColor(Color(hex: theme.editorBg))
        
        // Render markdown
        let attributed = renderMarkdown(markdown, theme: theme)
        if textView.attributedString() != attributed {
            textView.textStorage?.setAttributedString(attributed)
        }
        
        // Sync scroll position
        if syncEnabled {
            let maxScroll = max(1, (scrollView.documentView?.frame.height ?? 0) - scrollView.contentView.bounds.height)
            let targetY = maxScroll * scrollPercent
            let currentY = scrollView.contentView.bounds.origin.y
            if abs(targetY - currentY) > 5 {
                scrollView.contentView.scroll(to: NSPoint(x: 0, y: targetY))
            }
        }
    }
    
    private func renderMarkdown(_ text: String, theme: Theme) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let defaultAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 14),
            .foregroundColor: NSColor(Color(hex: theme.text))
        ]
        
        let doc = Document(parsing: text)
        for block in doc.children {
            renderBlock(block, into: result, theme: theme, defaultAttrs: defaultAttrs)
            result.append(NSAttributedString(string: "\n\n", attributes: defaultAttrs))
        }
        return result
    }
    
    private func renderBlock(_ block: any Markup, into result: NSMutableAttributedString, theme: Theme, defaultAttrs: [NSAttributedString.Key: Any]) {
        switch block {
        case let h as Heading:
            let sizes: [CGFloat] = [28, 24, 20, 17, 15, 14]
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.boldSystemFont(ofSize: sizes[min(h.level - 1, 5)]),
                .foregroundColor: NSColor(Color(hex: theme.heading))
            ]
            result.append(NSAttributedString(string: h.plainText, attributes: attrs))
            
        case let p as Paragraph:
            for child in p.children {
                renderInline(child, into: result, theme: theme, defaultAttrs: defaultAttrs)
            }
            
        case let code as CodeBlock:
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.monospacedSystemFont(ofSize: 12, weight: .regular),
                .foregroundColor: NSColor(Color(hex: theme.text)),
                .backgroundColor: NSColor.black.withAlphaComponent(0.2)
            ]
            result.append(NSAttributedString(string: code.code, attributes: attrs))
            
        case let list as UnorderedList:
            for item in list.listItems {
                result.append(NSAttributedString(string: "• ", attributes: defaultAttrs))
                for child in item.children {
                    if let p = child as? Paragraph {
                        for inline in p.children {
                            renderInline(inline, into: result, theme: theme, defaultAttrs: defaultAttrs)
                        }
                    }
                }
                result.append(NSAttributedString(string: "\n", attributes: defaultAttrs))
            }
            
        case let list as OrderedList:
            for (idx, item) in list.listItems.enumerated() {
                result.append(NSAttributedString(string: "\(idx + 1). ", attributes: defaultAttrs))
                for child in item.children {
                    if let p = child as? Paragraph {
                        for inline in p.children {
                            renderInline(inline, into: result, theme: theme, defaultAttrs: defaultAttrs)
                        }
                    }
                }
                result.append(NSAttributedString(string: "\n", attributes: defaultAttrs))
            }
            
        case let quote as BlockQuote:
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 14),
                .foregroundColor: NSColor(Color(hex: theme.comment))
            ]
            for child in quote.children {
                if let p = child as? Paragraph {
                    result.append(NSAttributedString(string: "│ ", attributes: attrs))
                    for inline in p.children {
                        renderInline(inline, into: result, theme: theme, defaultAttrs: attrs)
                    }
                }
            }
            
        default:
            result.append(NSAttributedString(string: block.format(), attributes: defaultAttrs))
        }
    }
    
    private func renderInline(_ inline: any Markup, into result: NSMutableAttributedString, theme: Theme, defaultAttrs: [NSAttributedString.Key: Any]) {
        switch inline {
        case let t as Markdown.Text:
            result.append(NSAttributedString(string: t.string, attributes: defaultAttrs))
        case let s as Strong:
            var attrs = defaultAttrs
            attrs[.font] = NSFont.boldSystemFont(ofSize: 14)
            attrs[.foregroundColor] = NSColor(Color(hex: theme.keyword))
            result.append(NSAttributedString(string: s.plainText, attributes: attrs))
        case let e as Emphasis:
            var attrs = defaultAttrs
            attrs[.font] = NSFont.systemFont(ofSize: 14).with(traits: .italicFontMask)
            attrs[.foregroundColor] = NSColor(Color(hex: theme.string))
            result.append(NSAttributedString(string: e.plainText, attributes: attrs))
        case let c as InlineCode:
            var attrs = defaultAttrs
            attrs[.font] = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
            attrs[.foregroundColor] = NSColor(Color(hex: theme.accent))
            result.append(NSAttributedString(string: c.code, attributes: attrs))
        case let l as Markdown.Link:
            var attrs = defaultAttrs
            attrs[.foregroundColor] = NSColor(Color(hex: theme.keyword))
            attrs[.underlineStyle] = NSUnderlineStyle.single.rawValue
            result.append(NSAttributedString(string: l.plainText, attributes: attrs))
        case is SoftBreak, is LineBreak:
            result.append(NSAttributedString(string: "\n", attributes: defaultAttrs))
        default:
            result.append(NSAttributedString(string: inline.format(), attributes: defaultAttrs))
        }
    }
}

private extension NSFont {
    func with(traits: NSFontTraitMask) -> NSFont {
        NSFontManager.shared.convert(self, toHaveTrait: traits)
    }
}
