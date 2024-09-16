import SwiftUI

/// Custom view modifier for applying a rounded border to a view.
struct RoundedBorder: ViewModifier {
    let cornerRadius: CGFloat
    let lineColor: Color
    let lineWidth: CGFloat

    func body(content: Content) -> some View {
        content
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(lineColor, lineWidth: lineWidth)
            }
    }
}

private extension RoundedBorder {
    enum Layout {
        static let height: CGFloat = 1
    }
}

extension View {
    /// Applies a rounded border to a view.
    func roundedBorder(cornerRadius: CGFloat, lineColor: Color, lineWidth: CGFloat) -> some View {
        self.modifier(RoundedBorder(cornerRadius: cornerRadius, lineColor: lineColor, lineWidth: lineWidth))
    }
}
