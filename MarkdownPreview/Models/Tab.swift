// Tab Model
import Foundation

struct Tab: Identifiable, Equatable, Codable {
    var id = UUID()
    var name: String
    var content: String
    var filePath: String?
    var isModified: Bool = false
    var isPinned: Bool = false
    
    var fileURL: URL? {
        get { filePath.map { URL(fileURLWithPath: $0) } }
        set { filePath = newValue?.path }
    }
    
    static func untitled() -> Tab {
        Tab(name: "Untitled.md", content: "")
    }
    
    static func welcome() -> Tab {
        Tab(
            name: "Welcome.md",
            content: """
            # Welcome to Render.md
            
            Start typing your markdown here...
            
            ## Features
            - **Bold** and *italic* text
            - `inline code`
            - Lists and blockquotes
            
            > This is a quote
            
            ```swift
            let greeting = "Hello, World!"
            ```
            """
        )
    }
}
