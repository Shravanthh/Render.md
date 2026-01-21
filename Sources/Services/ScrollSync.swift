// Scroll Sync - Synchronizes scroll position between editor and preview
import SwiftUI
import Combine

class ScrollSync: ObservableObject {
    @Published var scrollPercent: CGFloat = 0
    @Published var source: ScrollSource = .none
    
    enum ScrollSource { case none, editor, preview }
    
    func update(percent: CGFloat, from: ScrollSource) {
        guard source == .none || source == from else { return }
        source = from
        scrollPercent = percent
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.source = .none
        }
    }
}
