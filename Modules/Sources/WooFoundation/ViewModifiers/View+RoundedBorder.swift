import SwiftUI

/// Custom view modifier for applying a rounded border to a view.
public struct RoundedBorder: ViewModifier {
    let cornerRadius: CGFloat
    let lineColor: Color
    let lineWidth: CGFloat
    let dashed: Bool

    public init(cornerRadius: CGFloat, lineColor: Color, lineWidth: CGFloat, dashed: Bool) {
        self.cornerRadius = cornerRadius
        self.lineColor = lineColor
        self.lineWidth = lineWidth
        self.dashed = dashed
    }

    public func body(content: Content) -> some View {
        content
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(style: StrokeStyle(lineWidth: lineWidth, dash: dashed ? [Layout.dashLength] : []))
                    .foregroundStyle(lineColor)
            }
    }
}

private extension RoundedBorder {
    enum Layout {
        static let dashLength: CGFloat = 5
    }
}

public extension View {
    /// Applies a rounded border to a view.
    func roundedBorder(cornerRadius: CGFloat, lineColor: Color, lineWidth: CGFloat, dashed: Bool = false) -> some View {
        self.modifier(RoundedBorder(cornerRadius: cornerRadius, lineColor: lineColor, lineWidth: lineWidth, dashed: dashed))
    }
}
