// Find Bar View
import SwiftUI

struct FindBarView: View {
    @Binding var findText: String
    @Binding var replaceText: String
    let onClose: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Find", text: $findText)
                .textFieldStyle(.plain)
                .frame(width: 150)
            
            TextField("Replace", text: $replaceText)
                .textFieldStyle(.plain)
                .frame(width: 150)
            
            Button("Replace") { }
                .buttonStyle(.plain)
            
            Button("All") { }
                .buttonStyle(.plain)
            
            Spacer()
            
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.3))
    }
}
