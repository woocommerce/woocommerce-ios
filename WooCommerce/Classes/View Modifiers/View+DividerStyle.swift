import SwiftUI

/// Custom view modifier for applying the default divider style.
struct DividerStyle: ViewModifier {

    func body(content: Content) -> some View {
        content
            .foregroundColor(Color(.separator))
            .frame(height: Layout.height)
    }
}

private extension DividerStyle {
    enum Layout {
        static let height: CGFloat = 1
    }
}

extension View {
    /// Applies the default divider style to a view.
    func dividerStyle() -> some View {
        self.modifier(DividerStyle())
    }
}
