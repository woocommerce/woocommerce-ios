import SwiftUI

/// Custom view modifer for adding dividers on top and bottom of a view.
struct TopAndBottomDividers: ViewModifier {

    func body(content: Content) -> some View {
        VStack(spacing: 0) {
            Divider()
            content
            Divider()
        }
    }
}

extension View {
    /// Adds dividers on top and bottom of a view.
    func addingTopAndBottomDividers() -> some View {
        self.modifier(TopAndBottomDividers())
    }
}
