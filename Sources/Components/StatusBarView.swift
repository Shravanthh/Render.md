// Status Bar View
import SwiftUI

struct StatusBarView: View {
    let wordCount: Int
    let lineCount: Int
    let theme: Theme
    
    var body: some View {
        HStack {
            Text("Lines: \(lineCount)")
                .font(.system(size: 11))
            
            Divider()
                .frame(height: 12)
            
            Text("Words: \(wordCount)")
                .font(.system(size: 11))
            
            Spacer()
            
            Text("Markdown")
                .font(.system(size: 11))
        }
        .foregroundColor(Color(hex: theme.comment))
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(Color(hex: theme.bg).opacity(0.9))
    }
}
