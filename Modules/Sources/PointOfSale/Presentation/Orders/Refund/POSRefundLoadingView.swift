import SwiftUI

struct POSRefundLoadingView: View {
    @Environment(\.posModalParentSize) private var parentSize

    var body: some View {
        VStack(spacing: POSSpacing.xLarge) {
            ProgressView()
                .progressViewStyle(POSRefundModalLayout.progressViewStyle)

            Text(Localization.loadingMessage)
                .font(.posBodyLargeRegular())
                .foregroundColor(Color.posOnSurface)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(POSPadding.xLarge)
        .background(Color.posSurfaceBright)
        .clipShape(RoundedRectangle(cornerRadius: POSRefundModalLayout.cornerRadius))
        .frame(width: parentSize.width - (POSRefundModalLayout.horizontalPadding * 2))
    }
}

// MARK: - Localization

private extension POSRefundLoadingView {
    enum Localization {
        static let loadingMessage = NSLocalizedString(
            "pos.refundLoadingView.loadingMessage",
            value: "Loading refund details...",
            comment: "Message shown while loading refund information"
        )
    }
}

#if DEBUG
#Preview("POSRefundLoadingView") {
    POSRefundLoadingView()
        .environment(\.posModalParentSize, CGSize(width: 1192, height: 822))
}
#endif
