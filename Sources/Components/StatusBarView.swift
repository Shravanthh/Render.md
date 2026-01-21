// Status Bar View
import SwiftUI

struct StatusBarView: View {
    let wordCount: Int
    let lineCount: Int
    let theme: Theme
    @Binding var syncScroll: Bool
    
    var body: some View {
        HStack {
            Text("Lines: \(lineCount)")
                .font(.system(size: 11))
            
            Divider().frame(height: 12)
            
            Text("Words: \(wordCount)")
                .font(.system(size: 11))
            
            Spacer()
            
            Button {
                syncScroll.toggle()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: syncScroll ? "link" : "link.badge.plus")
                        .font(.system(size: 10))
                    Text(syncScroll ? "Sync On" : "Sync Off")
                        .font(.system(size: 11))
                }
                .foregroundColor(syncScroll ? Color(hex: theme.accent) : Color(hex: theme.comment))
            }
            .buttonStyle(.plain)
            .help("Toggle scroll sync between editor and preview")
            
            Divider().frame(height: 12)
            
            Text("Markdown")
                .font(.system(size: 11))
        }
        .foregroundColor(Color(hex: theme.comment))
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(Color(hex: theme.bg).opacity(0.9))
    }
}
