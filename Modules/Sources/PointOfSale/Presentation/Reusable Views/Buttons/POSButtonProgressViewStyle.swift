import SwiftUI
import struct WooFoundation.IndefiniteCircularProgressViewStyle

/// A view that displays an animated progress indicator with a circular shape.
struct POSButtonProgressViewStyle: ProgressViewStyle {
    private let size: CGFloat
    private let lineWidth: CGFloat

    /// - Parameters:
    ///   - size: dimension of the whole progress view.
    ///   - lineWidth: thickness of the circular progress indicator.
    init(size: CGFloat, lineWidth: CGFloat) {
        self.size = size
        self.lineWidth = lineWidth
    }

    func makeBody(configuration: Configuration) -> some View {
        ProgressView(configuration)
            .progressViewStyle(IndefiniteCircularProgressViewStyle(
                // The size (dimension) of the circle is adjusted by the lineWidth because half of the border line is drawn outside the circle frame.
                size: size - lineWidth,
                lineWidth: lineWidth,
                lineCap: .butt,
                circleColor: Color.posSecondary,
                fillColor: Color.posOnPrimary
            ))
    }
}
