// Sidebar View
import SwiftUI

struct SidebarView: View {
    let folderURL: URL?
    let onSelect: (URL) -> Void
    let onOpenFolder: () -> Void
    
    @State private var files: [URL] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let folder = folderURL {
                folderHeader(folder)
                fileList
            } else {
                emptyState
            }
        }
        .background(Color.black.opacity(0.3))
        .onAppear { loadFiles() }
        .onChange(of: folderURL) { _ in loadFiles() }
    }
    
    // MARK: - Subviews
    private func folderHeader(_ folder: URL) -> some View {
        HStack {
            Image(systemName: "folder.fill")
                .foregroundColor(.blue)
            Text(folder.lastPathComponent)
                .font(.system(size: 12, weight: .semibold))
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.05))
    }
    
    private var fileList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 2) {
                ForEach(files, id: \.self) { file in
                    FileRowView(file: file, onSelect: onSelect)
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 32))
                .foregroundColor(.secondary)
            Text("No folder open")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            Button("Open Folder", action: onOpenFolder)
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Data Loading
    private func loadFiles() {
        guard let folder = folderURL else {
            files = []
            return
        }
        files = FileService.shared.markdownFiles(in: folder)
    }
}

// MARK: - File Row
struct FileRowView: View {
    let file: URL
    let onSelect: (URL) -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        Button { onSelect(file) } label: {
            HStack(spacing: 6) {
                Image(systemName: "doc.text")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Text(file.lastPathComponent)
                    .font(.system(size: 12))
                    .lineLimit(1)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isHovering ? Color.white.opacity(0.05) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }
}
