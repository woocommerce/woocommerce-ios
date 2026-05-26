import SwiftUI

struct POSRefundLoadingView: View {
    let onBack: () -> Void

    @Environment(\.posModalParentSize) private var parentSize
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Namespace private var loadingNamespace

    var body: some View {
        ZStack(alignment: .topLeading) {
            loadingContent
            headerView
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.posSurfaceBright)
        .posRefundModalFrame(parentSize: parentSize, horizontalSizeClass: horizontalSizeClass)
    }
}

// MARK: - Subviews

private extension POSRefundLoadingView {
    var headerView: some View {
        POSRefundNavigationHeader(backAction: onBack,
                                  backAccessibilityLabel: Localization.backButtonAccessibilityLabel)
    }

    var loadingContent: some View {
        VStack(spacing: POSSpacing.none) {
            POSPaymentLoadingView(title: Localization.loadingTitle,
                                  message: Localization.loadingMessage,
                                  animation: .init(namespace: loadingNamespace))
            .padding(.horizontal, POSPadding.xLarge)
            .frame(maxWidth: POSRefundModalLayout.fullScreenContentMaxWidth)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Localization

private extension POSRefundLoadingView {
    enum Localization {
        static let loadingTitle = NSLocalizedString(
            "pos.refundLoadingView.loadingTitle",
            value: "Getting refund ready",
            comment: "Title shown while loading refund information"
        )

        static let backButtonAccessibilityLabel = NSLocalizedString(
            "pos.refundLoadingView.backButton.accessibilityLabel",
            value: "Back",
            comment: "Accessibility label for the back button on the refund loading screen"
        )

        static let loadingMessage = NSLocalizedString(
            "pos.refundLoadingView.loadingMessage",
            value: "Loading refund details",
            comment: "Message shown while loading refund information"
        )
    }
}

#if DEBUG
#Preview("POSRefundLoadingView") {
    POSRefundLoadingView(onBack: {})
        .environment(\.posModalParentSize, CGSize(width: 1192, height: 822))
}
#endif
