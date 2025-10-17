import SwiftUI
import struct WooFoundation.IndefiniteCircularProgressViewStyle

struct POSProgressViewStyle: ProgressViewStyle {
    let size: CGFloat
    let lineWidth: CGFloat

    init(size: CGFloat = 108, lineWidth: CGFloat = 48) {
        self.size = size
        self.lineWidth = lineWidth
    }

    func makeBody(configuration: Configuration) -> some View {
        ProgressView(configuration)
            .progressViewStyle(IndefiniteCircularProgressViewStyle(
                size: size,
                lineWidth: lineWidth,
                lineCap: .butt,
                circleColor: Color.posSecondary,
                fillColor: Color.posPrimary
            ))
    }
}
