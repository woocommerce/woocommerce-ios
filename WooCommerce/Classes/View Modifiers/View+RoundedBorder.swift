import SwiftUI

/// Custom view modifier for applying a rounded border to a view.
struct RoundedBorder: ViewModifier {
    let cornerRadius: CGFloat
    let lineColor: Color
    let lineWidth: CGFloat
    let dashed: Bool

    func body(content: Content) -> some View {
        content
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(style: StrokeStyle(lineWidth: lineWidth, dash: [dashed ? Layout.dashLength : 1]))
                    .foregroundStyle(lineColor)
            }
    }
}

private extension RoundedBorder {
    enum Layout {
        static let height: CGFloat = 1
        static let dashLength: CGFloat = 5
    }
}

extension View {
    /// Applies a rounded border to a view.
    func roundedBorder(cornerRadius: CGFloat, lineColor: Color, lineWidth: CGFloat, dashed: Bool = false) -> some View {
        self.modifier(RoundedBorder(cornerRadius: cornerRadius, lineColor: lineColor, lineWidth: lineWidth, dashed: dashed))
    }
}
