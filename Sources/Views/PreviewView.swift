// Preview View - Rendered Markdown
import SwiftUI
import Markdown

struct PreviewView: View {
    let markdown: String
    let theme: Theme
    var scrollSync: ScrollSync?
    
    var body: some View {
        GeometryReader { outer in
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 14) {
                        ForEach(Array(Document(parsing: markdown).children.enumerated()), id: \.offset) { idx, block in
                            BlockView(block: block, theme: theme)
                                .id(idx)
                        }
                        Spacer(minLength: 100)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(GeometryReader { inner in
                        Color.clear.preference(key: ScrollOffsetKey.self, value: inner.frame(in: .named("preview")).minY)
                    })
                }
                .coordinateSpace(name: "preview")
                .onPreferenceChange(ScrollOffsetKey.self) { offset in
                    guard let sync = scrollSync, sync.source != .editor else { return }
                    let contentHeight = max(1, outer.size.height * 2)
                    let percent = -offset / contentHeight
                    sync.update(percent: min(max(percent, 0), 1), from: .preview)
                }
                .onChange(of: scrollSync?.scrollPercent) { percent in
                    guard let sync = scrollSync, let p = percent, sync.source == .editor else { return }
                    let blocks = Array(Document(parsing: markdown).children)
                    let targetIdx = Int(p * CGFloat(blocks.count))
                    withAnimation(.easeOut(duration: 0.1)) {
                        proxy.scrollTo(min(targetIdx, max(0, blocks.count - 1)), anchor: .top)
                    }
                }
            }
        }
        .background(Color(hex: theme.editorBg))
        .foregroundColor(Color(hex: theme.text))
    }
}

private struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

struct BlockView: View {
    let block: any Markup
    let theme: Theme
    
    var body: some View {
        switch block {
        case let h as Heading:
            SwiftUI.Text(h.plainText)
                .font(.system(size: [32, 26, 20, 16, 14, 12][min(h.level - 1, 5)]))
                .fontWeight(.bold)
                .foregroundColor(Color(hex: theme.heading))
                .padding(.top, 8)
        case let p as Paragraph: InlineText(children: Array(p.children), theme: theme)
        case let code as CodeBlock: CodeBlockView(code: code, theme: theme)
        case let list as UnorderedList: UnorderedListView(list: list, theme: theme)
        case let list as OrderedList: OrderedListView(list: list, theme: theme)
        case let quote as BlockQuote: QuoteView(quote: quote, theme: theme)
        case is ThematicBreak: Divider().padding(.vertical, 8)
        default: SwiftUI.Text(block.format())
        }
    }
}

struct InlineText: View {
    let children: [any Markup]
    let theme: Theme
    
    var body: some View {
        children.reduce(SwiftUI.Text("")) { result, child in
            result + render(child)
        }
    }
    
    private func render(_ m: any Markup) -> SwiftUI.Text {
        switch m {
        case let t as Markdown.Text: return SwiftUI.Text(t.string)
        case let s as Strong: return SwiftUI.Text(s.plainText).bold().foregroundColor(Color(hex: theme.keyword))
        case let e as Emphasis: return SwiftUI.Text(e.plainText).italic().foregroundColor(Color(hex: theme.string))
        case let c as InlineCode: return SwiftUI.Text(c.code).font(.system(.body, design: .monospaced)).foregroundColor(Color(hex: theme.accent))
        case let l as Markdown.Link: return SwiftUI.Text(l.plainText).foregroundColor(Color(hex: theme.keyword)).underline()
        case is SoftBreak, is LineBreak: return SwiftUI.Text("\n")
        default: return SwiftUI.Text(m.format())
        }
    }
}

struct CodeBlockView: View {
    let code: CodeBlock
    let theme: Theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let lang = code.language {
                SwiftUI.Text(lang).font(.system(size: 11)).foregroundColor(Color(hex: theme.comment)).padding(.horizontal, 12).padding(.top, 8)
            }
            SwiftUI.Text(code.code).font(.system(size: 13, design: .monospaced)).foregroundColor(Color(hex: theme.text)).padding(12)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.black.opacity(0.3))
        .cornerRadius(8)
    }
}

struct UnorderedListView: View {
    let list: UnorderedList
    let theme: Theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(list.listItems.enumerated()), id: \.offset) { _, item in
                HStack(alignment: .top, spacing: 10) {
                    SwiftUI.Text("•").foregroundColor(Color(hex: theme.accent))
                    VStack(alignment: .leading) {
                        ForEach(Array(item.children.enumerated()), id: \.offset) { _, child in
                            if let p = child as? Paragraph { InlineText(children: Array(p.children), theme: theme) }
                        }
                    }
                }
            }
        }
    }
}

struct OrderedListView: View {
    let list: OrderedList
    let theme: Theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(list.listItems.enumerated()), id: \.offset) { idx, item in
                HStack(alignment: .top, spacing: 10) {
                    SwiftUI.Text("\(idx + 1).").foregroundColor(Color(hex: theme.accent))
                    VStack(alignment: .leading) {
                        ForEach(Array(item.children.enumerated()), id: \.offset) { _, child in
                            if let p = child as? Paragraph { InlineText(children: Array(p.children), theme: theme) }
                        }
                    }
                }
            }
        }
    }
}

struct QuoteView: View {
    let quote: BlockQuote
    let theme: Theme
    
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 2).fill(Color(hex: theme.accent)).frame(width: 4)
            VStack(alignment: .leading) {
                ForEach(Array(quote.children.enumerated()), id: \.offset) { _, child in
                    if let p = child as? Paragraph { InlineText(children: Array(p.children), theme: theme) }
                }
            }
        }
        .foregroundColor(Color(hex: theme.comment))
    }
}
