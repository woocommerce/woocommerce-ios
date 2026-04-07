import SwiftUI

/// View modifier that wraps content in a vertical `ScrollView` that only scrolls when content exceeds the available height.
/// Content that fits within the viewport fills the space normally (Spacers expand, no bounce).
///
public struct ConditionalVerticalScrollModifier: ViewModifier {
    public func body(content: Content) -> some View {
        GeometryReader { parentGeometry in
            ScrollView(.vertical, showsIndicators: false) {
                content
                    .frame(minHeight: parentGeometry.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
            .contentMargins(0, for: .scrollContent)
        }
    }
}

// MARK: View Extensions

public extension View {
    /// Allows the view to scroll vertically when the content height is greater than its parent height.
    ///
    func scrollVerticallyIfNeeded() -> some View {
        self.modifier(ConditionalVerticalScrollModifier())
    }
}
