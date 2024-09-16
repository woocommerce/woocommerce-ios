import SwiftUI
import WooFoundation

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
                circleColor: Color(.wooCommercePurple(.shade10)),
                fillColor: Color(.wooCommercePurple(.shade50))
            ))
    }
}
