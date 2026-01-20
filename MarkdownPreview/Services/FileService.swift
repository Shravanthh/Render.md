// File Service - Handles all file operations
import AppKit
import UniformTypeIdentifiers

final class FileService {
    static let shared = FileService()
    private init() {}
    
    // MARK: - Open
    func openFiles() -> [URL] {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [UTType(filenameExtension: "md")!, .plainText]
        panel.allowsMultipleSelection = true
        guard panel.runModal() == .OK else { return [] }
        return panel.urls
    }
    
    func openFolder() -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        guard panel.runModal() == .OK else { return nil }
        return panel.url
    }
    
    func loadContent(from url: URL) -> String? {
        try? String(contentsOf: url)
    }
    
    // MARK: - Save
    func save(content: String, to url: URL) -> Bool {
        do {
            try content.write(to: url, atomically: true, encoding: .utf8)
            return true
        } catch {
            return false
        }
    }
    
    func saveAs(content: String, suggestedName: String) -> URL? {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType(filenameExtension: "md", conformingTo: .text)!]
        panel.nameFieldStringValue = suggestedName.hasSuffix(".md") ? suggestedName : suggestedName + ".md"
        
        guard panel.runModal() == .OK, var url = panel.url else { return nil }
        
        if url.pathExtension.lowercased() != "md" {
            url.deletePathExtension()
            url.appendPathExtension("md")
        }
        
        return save(content: content, to: url) ? url : nil
    }
    
    // MARK: - Folder Contents
    func markdownFiles(in folder: URL) -> [URL] {
        let fm = FileManager.default
        guard let contents = try? fm.contentsOfDirectory(
            at: folder,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }
        
        return contents
            .filter { $0.pathExtension.lowercased() == "md" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
    }
    
    // MARK: - Export
    func exportHTML(content: String, name: String) {
        let html = HTMLExporter.convert(markdown: content)
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.html]
        panel.nameFieldStringValue = name.replacingOccurrences(of: ".md", with: ".html")
        
        if panel.runModal() == .OK, let url = panel.url {
            try? html.write(to: url, atomically: true, encoding: .utf8)
        }
    }
    
    func exportPDF(content: String, name: String) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = name.replacingOccurrences(of: ".md", with: ".pdf")
        
        guard panel.runModal() == .OK, let url = panel.url else { return }
        
        let printInfo = NSPrintInfo()
        printInfo.paperSize = NSSize(width: 612, height: 792)
        printInfo.topMargin = 36
        printInfo.bottomMargin = 36
        printInfo.leftMargin = 36
        printInfo.rightMargin = 36
        
        let view = NSTextView(frame: NSRect(x: 0, y: 0, width: 540, height: 720))
        view.textStorage?.setAttributedString(NSAttributedString(string: content))
        
        let op = NSPrintOperation.pdfOperation(with: view, inside: view.bounds, toPath: url.path, printInfo: printInfo)
        op.showsPrintPanel = false
        op.showsProgressPanel = false
        op.run()
    }
}

// MARK: - HTML Exporter
enum HTMLExporter {
    static func convert(markdown: String) -> String {
        // Simple markdown to HTML conversion
        var html = """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="UTF-8">
        <style>
        body { font-family: -apple-system, system-ui; max-width: 800px; margin: 40px auto; padding: 20px; background: #1e1e1e; color: #d4d4d4; }
        h1, h2, h3 { color: #bd93f9; }
        code { background: #282a36; padding: 2px 6px; border-radius: 4px; }
        pre { background: #282a36; padding: 16px; border-radius: 8px; overflow-x: auto; }
        blockquote { border-left: 4px solid #bd93f9; margin: 0; padding-left: 16px; color: #6272a4; }
        </style>
        </head>
        <body>
        """
        
        // Basic conversion
        let lines = markdown.components(separatedBy: "\n")
        for line in lines {
            if line.hasPrefix("# ") {
                html += "<h1>\(line.dropFirst(2))</h1>\n"
            } else if line.hasPrefix("## ") {
                html += "<h2>\(line.dropFirst(3))</h2>\n"
            } else if line.hasPrefix("### ") {
                html += "<h3>\(line.dropFirst(4))</h3>\n"
            } else if line.hasPrefix("> ") {
                html += "<blockquote>\(line.dropFirst(2))</blockquote>\n"
            } else if line.hasPrefix("- ") {
                html += "<li>\(line.dropFirst(2))</li>\n"
            } else if !line.isEmpty {
                html += "<p>\(line)</p>\n"
            }
        }
        
        html += "</body></html>"
        return html
    }
}
