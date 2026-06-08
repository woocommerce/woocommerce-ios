import SwiftUI

struct POSRefundNothingToRefundView: View {
    let onClose: () -> Void

    @Environment(\.posModalParentSize) private var parentSize
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        VStack(spacing: POSSpacing.none) {
            headerView
            Spacer(minLength: POSSpacing.large)
            contentView
            Spacer(minLength: POSSpacing.large)
            buttonsSection
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.posSurfaceBright)
        .posRefundModalFrame(parentSize: parentSize, horizontalSizeClass: horizontalSizeClass)
    }
}

// MARK: - Subviews

private extension POSRefundNothingToRefundView {
    var headerView: some View {
        POSRefundNavigationHeader(backAction: onClose,
                                  backAccessibilityLabel: Localization.backButtonAccessibilityLabel)
    }

    var contentView: some View {
        VStack(spacing: POSSpacing.small) {
            Text(Localization.title)
                .font(.posHeadingBold)
                .foregroundColor(Color.posOnSurface)
                .accessibilityAddTraits(.isHeader)

            Text(Localization.message)
                .font(.posBodyLargeRegular())
                .foregroundColor(Color.posOnSurface)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, POSPadding.xLarge)
        .frame(maxWidth: POSRefundModalLayout.fullScreenContentMaxWidth)
    }

    var buttonsSection: some View {
        Button(Localization.doneButton, action: onClose)
            .buttonStyle(POSFilledButtonStyle(size: .normal))
            .posCompactFullScreenButtonPadding(horizontalSizeClass: horizontalSizeClass)
    }
}

// MARK: - Localization

private extension POSRefundNothingToRefundView {
    enum Localization {
        static let title = NSLocalizedString(
            "pos.refundNothingToRefundView.title",
            value: "Nothing to refund",
            comment: "Title shown when there are no items available to refund"
        )

        static let backButtonAccessibilityLabel = NSLocalizedString(
            "pos.refundNothingToRefundView.backButton.accessibilityLabel",
            value: "Back",
            comment: "Accessibility label for the back button on the nothing to refund screen"
        )

        static let message = NSLocalizedString(
            "pos.refundNothingToRefundView.message",
            value: "All items in this order have already been refunded.",
            comment: "Message explaining why there are no items to refund"
        )

        static let doneButton = NSLocalizedString(
            "pos.refundNothingToRefundView.doneButton",
            value: "Done",
            comment: "Button to dismiss the nothing to refund screen"
        )
    }
}

#if DEBUG
#Preview("POSRefundNothingToRefundView") {
    POSRefundNothingToRefundView(
        onClose: {}
    )
    .environment(\.posModalParentSize, CGSize(width: 1192, height: 822))
}
#endif
