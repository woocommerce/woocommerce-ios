import SwiftUI
import WooFoundation

struct PointOfSaleCardPresentPaymentReaderUpdateProgressView: View {
    @Environment(\.posMetrics) private var metrics
    let progress: CGFloat
    let isComplete: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.posSecondary)
                .frame(width: Constants.size, height: Constants.size)

            Circle()
                .fill(Color.posPrimary)
                .frame(width: Constants.size - metrics.spacing.xSmall, height: Constants.size - metrics.spacing.xSmall)
                .clipShape(
                    Rectangle()
                        .offset(y: (1 - progress) * Constants.size)
                )
                .animation(.easeOut(duration: 0.2), value: progress)

            (
                isComplete ? SharedImageAsset.cardReaderUpdateProgressCheckmark.decorativeImage : SharedImageAsset.cardReaderUpdateProgressArrow.decorativeImage
            )
                .renderingMode(.template)
                .foregroundColor(Color.posOnPrimary)
        }
        .frame(width: Constants.size, height: Constants.size)
    }
}

private enum Constants {
    static let size: CGFloat = 100
}

#Preview {
    @Previewable @State var progress: CGFloat = 0.5

    VStack(spacing: POSMetrics.regular.spacing.large) {
        PointOfSaleCardPresentPaymentReaderUpdateProgressView(progress: progress, isComplete: progress >= 1.0)
        Slider(value: $progress, in: 0...1)
    }
    .posPadding(\.medium)
}
