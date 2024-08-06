import SwiftUI
import WooFoundation

struct POSProgressViewStyle: ProgressViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        ProgressView(configuration)
            .progressViewStyle(IndefiniteCircularProgressViewStyle(
                size: 108,
                lineWidth: 48,
                lineCap: .butt,
                circleColor: Color(.wooCommercePurple(.shade10)),
                fillColor: Color(.wooCommercePurple(.shade50))
            ))
    }
}
