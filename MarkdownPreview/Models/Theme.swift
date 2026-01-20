// Theme Model
import SwiftUI

struct Theme: Equatable {
    let name: String
    let bg: String
    let editorBg: String
    let text: String
    let accent: String
    let comment: String
    let keyword: String
    let string: String
    let heading: String
    
    static let dracula = Theme(
        name: "Dracula",
        bg: "#282a36", editorBg: "#282a36", text: "#f8f8f2",
        accent: "#bd93f9", comment: "#6272a4", keyword: "#ff79c6",
        string: "#f1fa8c", heading: "#bd93f9"
    )
    
    static let monokai = Theme(
        name: "Monokai",
        bg: "#272822", editorBg: "#272822", text: "#f8f8f2",
        accent: "#a6e22e", comment: "#75715e", keyword: "#f92672",
        string: "#e6db74", heading: "#66d9ef"
    )
    
    static let oneDark = Theme(
        name: "One Dark",
        bg: "#282c34", editorBg: "#282c34", text: "#abb2bf",
        accent: "#61afef", comment: "#5c6370", keyword: "#c678dd",
        string: "#98c379", heading: "#e5c07b"
    )
    
    static let github = Theme(
        name: "GitHub Dark",
        bg: "#0d1117", editorBg: "#0d1117", text: "#c9d1d9",
        accent: "#58a6ff", comment: "#8b949e", keyword: "#ff7b72",
        string: "#a5d6ff", heading: "#58a6ff"
    )
    
    static let all: [Theme] = [dracula, monokai, oneDark, github]
}
