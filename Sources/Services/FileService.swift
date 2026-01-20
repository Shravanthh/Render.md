// File Service - Handles all file operations
import AppKit
import UniformTypeIdentifiers

final class FileService {
    static let shared = FileService()
    private init() {}
    
    private let mdType = UTType(filenameExtension: "md")!
    
    func openFiles() -> [URL] {
        runOpenPanel(allowsMultiple: true, types: [mdType, .plainText])
    }
    
    func openFolder() -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        return panel.runModal() == .OK ? panel.url : nil
    }
    
    func loadContent(from url: URL) -> String? { try? String(contentsOf: url) }
    
    func save(content: String, to url: URL) -> Bool {
        (try? content.write(to: url, atomically: true, encoding: .utf8)) != nil
    }
    
    func saveAs(content: String, suggestedName: String) -> URL? {
        guard let url = runSavePanel(name: suggestedName.ensureMD, type: mdType) else { return nil }
        return save(content: content, to: url) ? url : nil
    }
    
    func markdownFiles(in folder: URL) -> [URL] {
        (try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil, options: .skipsHiddenFiles))?
            .filter { $0.pathExtension.lowercased() == "md" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent } ?? []
    }
    
    func exportHTML(content: String, name: String) {
        guard let url = runSavePanel(name: name.replacingOccurrences(of: ".md", with: ".html"), type: .html) else { return }
        try? HTMLExporter.convert(content).write(to: url, atomically: true, encoding: .utf8)
    }
    
    func exportPDF(content: String, name: String) {
        guard let url = runSavePanel(name: name.replacingOccurrences(of: ".md", with: ".pdf"), type: .pdf) else { return }
        let info = NSPrintInfo()
        info.paperSize = NSSize(width: 612, height: 792)
        info.topMargin = 36
        info.bottomMargin = 36
        info.leftMargin = 36
        info.rightMargin = 36
        
        let view = NSTextView(frame: NSRect(x: 0, y: 0, width: 540, height: 720))
        view.textStorage?.setAttributedString(NSAttributedString(string: content))
        
        let op = NSPrintOperation.pdfOperation(with: view, inside: view.bounds, toPath: url.path, printInfo: info)
        op.showsPrintPanel = false
        op.showsProgressPanel = false
        op.run()
    }
    
    private func runOpenPanel(allowsMultiple: Bool, types: [UTType]) -> [URL] {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = types
        panel.allowsMultipleSelection = allowsMultiple
        return panel.runModal() == .OK ? panel.urls : []
    }
    
    private func runSavePanel(name: String, type: UTType) -> URL? {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [type]
        panel.nameFieldStringValue = name
        return panel.runModal() == .OK ? panel.url : nil
    }
}

private extension String {
    var ensureMD: String { hasSuffix(".md") ? self : self + ".md" }
}

enum HTMLExporter {
    static func convert(_ markdown: String) -> String {
        let style = """
        body{font-family:-apple-system,system-ui;max-width:800px;margin:40px auto;padding:20px;background:#1e1e1e;color:#d4d4d4}
        h1,h2,h3{color:#bd93f9}code{background:#282a36;padding:2px 6px;border-radius:4px}
        pre{background:#282a36;padding:16px;border-radius:8px;overflow-x:auto}
        blockquote{border-left:4px solid #bd93f9;margin:0;padding-left:16px;color:#6272a4}
        """
        let body = markdown.components(separatedBy: "\n").map { line -> String in
            if line.hasPrefix("### ") { return "<h3>\(line.dropFirst(4))</h3>" }
            if line.hasPrefix("## ") { return "<h2>\(line.dropFirst(3))</h2>" }
            if line.hasPrefix("# ") { return "<h1>\(line.dropFirst(2))</h1>" }
            if line.hasPrefix("> ") { return "<blockquote>\(line.dropFirst(2))</blockquote>" }
            if line.hasPrefix("- ") { return "<li>\(line.dropFirst(2))</li>" }
            return line.isEmpty ? "" : "<p>\(line)</p>"
        }.joined(separator: "\n")
        return "<!DOCTYPE html><html><head><meta charset=\"UTF-8\"><style>\(style)</style></head><body>\(body)</body></html>"
    }
}
