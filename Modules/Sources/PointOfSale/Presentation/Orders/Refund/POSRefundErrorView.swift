import SwiftUI

struct POSRefundErrorView: View {
    @Environment(\.posMetrics) private var metrics
    let title: String
    let subtitle: String
    let onRetry: (() -> Void)?
    /// Label for the primary action. Defaults to "Retry"; a recovery that is not a retry, such as
    /// reloading the refundable items, passes its own.
    let retryButtonTitle: String?
    let cancelButtonTitle: String?
    let onCancel: () -> Void
    let onClose: () -> Void

    @Environment(\.posModalParentSize) private var parentSize
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    init(title: String,
         subtitle: String,
         onRetry: (() -> Void)?,
         retryButtonTitle: String? = nil,
         cancelButtonTitle: String? = nil,
         onCancel: @escaping () -> Void,
         onClose: @escaping () -> Void) {
        self.title = title
        self.subtitle = subtitle
        self.onRetry = onRetry
        self.retryButtonTitle = retryButtonTitle
        self.cancelButtonTitle = cancelButtonTitle
        self.onCancel = onCancel
        self.onClose = onClose
    }

    var body: some View {
        VStack(spacing: metrics.spacing.none) {
            headerView
            POSStatusScreenLayout {
                contentView
            } buttons: {
                buttonsSection
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.posSurfaceBright)
        .posRefundModalFrame(parentSize: parentSize, horizontalSizeClass: horizontalSizeClass)
    }
}

// MARK: - Subviews

private extension POSRefundErrorView {
    var headerView: some View {
        POSRefundNavigationHeader(backAction: onClose,
                                  backAccessibilityLabel: Localization.backButtonAccessibilityLabel)
    }

    var contentView: some View {
        VStack(spacing: metrics.spacing.xLarge) {
            POSErrorXMark()

            VStack(spacing: metrics.spacing.small) {
                Text(title)
                    .font(.posHeadingBold)
                    .foregroundColor(Color.posOnSurface)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)

                Text(subtitle)
                    .font(.posBodyLargeRegular())
                    .foregroundColor(Color.posOnSurface)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .multilineTextAlignment(.center)
        }
        .padding(.horizontal, metrics.padding.xLarge)
        .frame(maxWidth: POSRefundModalLayout.fullScreenContentMaxWidth)
    }

    var buttonsSection: some View {
        VStack(spacing: metrics.spacing.medium) {
            if let onRetry {
                Button(retryButtonTitle ?? Localization.retryButton, action: onRetry)
                    .buttonStyle(POSFilledButtonStyle(size: .normal))
            }

            Button(cancelButtonTitle ?? Localization.cancelButton, action: onCancel)
                .buttonStyle(POSOutlinedButtonStyle(size: .normal))
        }
    }
}

// MARK: - Localization

private extension POSRefundErrorView {
    enum Localization {
        static let backButtonAccessibilityLabel = NSLocalizedString(
            "pos.refundErrorView.backButton.accessibilityLabel",
            value: "Back",
            comment: "Accessibility label for the back button on the refund error screen"
        )

        static let retryButton = NSLocalizedString(
            "pos.refundErrorView.retryButton",
            value: "Retry",
            comment: "Button to retry the refund creation"
        )

        static let cancelButton = NSLocalizedString(
            "pos.refundErrorView.cancelButton",
            value: "Cancel",
            comment: "Button to cancel and dismiss the refund error screen"
        )
    }
}

#if DEBUG
#Preview("POSRefundErrorView - Create Error") {
    POSRefundErrorView(
        title: "Failed to create refund",
        subtitle: "Please try again.",
        onRetry: {},
        onCancel: {},
        onClose: {}
    )
    .posPreviewModalParentSize()
}

#Preview("POSRefundErrorView - Load Error") {
    POSRefundErrorView(
        title: "Couldn't load refund details",
        subtitle: "Please try again.",
        onRetry: {},
        onCancel: {},
        onClose: {}
    )
    .posPreviewModalParentSize()
}
#endif
