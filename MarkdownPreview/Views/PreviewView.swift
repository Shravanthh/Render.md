// Preview View - Rendered Markdown
import SwiftUI
import Markdown

struct PreviewView: View {
    let markdown: String
    let theme: Theme
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                ForEach(Array(Document(parsing: markdown).children.enumerated()), id: \.offset) { _, block in
                    BlockView(block: block, theme: theme)
                }
                Spacer(minLength: 100)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color(hex: theme.editorBg))
        .foregroundColor(Color(hex: theme.text))
    }
}

// MARK: - Block Rendering
struct BlockView: View {
    let block: any Markup
    let theme: Theme
    
    var body: some View {
        content
    }
    
    @ViewBuilder
    private var content: some View {
        switch block {
        case let h as Heading:
            Text(h.plainText)
                .font(headingFont(h.level))
                .fontWeight(.bold)
                .foregroundColor(Color(hex: theme.heading))
                .padding(.top, 8)
            
        case let p as Paragraph:
            InlineTextView(paragraph: p, theme: theme)
            
        case let code as CodeBlock:
            CodeBlockView(code: code, theme: theme)
            
        case let list as UnorderedList:
            UnorderedListView(list: list, theme: theme)
            
        case let list as OrderedList:
            OrderedListView(list: list, theme: theme)
            
        case let quote as BlockQuote:
            BlockQuoteView(quote: quote, theme: theme)
            
        case is ThematicBreak:
            Divider().padding(.vertical, 8)
            
        default:
            Text(block.format())
        }
    }
    
    private func headingFont(_ level: Int) -> Font {
        switch level {
        case 1: return .system(size: 32)
        case 2: return .system(size: 26)
        case 3: return .system(size: 20)
        default: return .system(size: 16)
        }
    }
}

// MARK: - Inline Text
struct InlineTextView: View {
    let paragraph: Paragraph
    let theme: Theme
    
    var body: some View {
        paragraph.children.reduce(SwiftUI.Text("")) { result, child in
            result + renderInline(child)
        }
    }
    
    private func renderInline(_ markup: any Markup) -> SwiftUI.Text {
        switch markup {
        case let t as Markdown.Text:
            return SwiftUI.Text(t.string)
        case let s as Strong:
            return SwiftUI.Text(s.plainText).bold().foregroundColor(Color(hex: theme.keyword))
        case let e as Emphasis:
            return SwiftUI.Text(e.plainText).italic().foregroundColor(Color(hex: theme.string))
        case let c as InlineCode:
            return SwiftUI.Text(c.code).font(.system(.body, design: .monospaced)).foregroundColor(Color(hex: theme.accent))
        case let l as Markdown.Link:
            return SwiftUI.Text(l.plainText).foregroundColor(Color(hex: theme.keyword)).underline()
        case is SoftBreak, is LineBreak:
            return SwiftUI.Text("\n")
        default:
            return SwiftUI.Text(markup.format())
        }
    }
}

// MARK: - Code Block
struct CodeBlockView: View {
    let code: CodeBlock
    let theme: Theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let lang = code.language {
                Text(lang)
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: theme.comment))
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
            }
            Text(code.code)
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(Color(hex: theme.text))
                .padding(12)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.black.opacity(0.3))
        .cornerRadius(8)
    }
}

// MARK: - Lists
struct UnorderedListView: View {
    let list: UnorderedList
    let theme: Theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(list.listItems.enumerated()), id: \.offset) { _, item in
                HStack(alignment: .top, spacing: 10) {
                    Text("•").foregroundColor(Color(hex: theme.accent))
                    VStack(alignment: .leading) {
                        ForEach(Array(item.children.enumerated()), id: \.offset) { _, child in
                            if let p = child as? Paragraph {
                                InlineTextView(paragraph: p, theme: theme)
                            }
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
                    Text("\(idx + 1).").foregroundColor(Color(hex: theme.accent))
                    VStack(alignment: .leading) {
                        ForEach(Array(item.children.enumerated()), id: \.offset) { _, child in
                            if let p = child as? Paragraph {
                                InlineTextView(paragraph: p, theme: theme)
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Block Quote
struct BlockQuoteView: View {
    let quote: BlockQuote
    let theme: Theme
    
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(hex: theme.accent))
                .frame(width: 4)
            VStack(alignment: .leading) {
                ForEach(Array(quote.children.enumerated()), id: \.offset) { _, child in
                    if let p = child as? Paragraph {
                        InlineTextView(paragraph: p, theme: theme)
                    }
                }
            }
        }
        .foregroundColor(Color(hex: theme.comment))
    }
}
