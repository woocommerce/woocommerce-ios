import SwiftUI

struct POSRefundErrorView: View {
    let title: String
    let subtitle: String
    let onRetry: (() -> Void)?
    let cancelButtonTitle: String?
    let onCancel: () -> Void
    let onClose: () -> Void

    @Environment(\.posModalParentSize) private var parentSize
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    init(title: String,
         subtitle: String,
         onRetry: (() -> Void)?,
         cancelButtonTitle: String? = nil,
         onCancel: @escaping () -> Void,
         onClose: @escaping () -> Void) {
        self.title = title
        self.subtitle = subtitle
        self.onRetry = onRetry
        self.cancelButtonTitle = cancelButtonTitle
        self.onCancel = onCancel
        self.onClose = onClose
    }

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

private extension POSRefundErrorView {
    var headerView: some View {
        POSRefundNavigationHeader(backAction: onClose,
                                  backAccessibilityLabel: Localization.backButtonAccessibilityLabel)
    }

    var contentView: some View {
        VStack(spacing: POSSpacing.xLarge) {
            POSErrorXMark()

            VStack(spacing: POSSpacing.small) {
                Text(title)
                    .font(.posHeadingBold)
                    .foregroundColor(Color.posOnSurface)
                    .accessibilityAddTraits(.isHeader)

                Text(subtitle)
                    .font(.posBodyLargeRegular())
                    .foregroundColor(Color.posOnSurface)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .multilineTextAlignment(.center)
        }
        .padding(.horizontal, POSPadding.xLarge)
        .frame(maxWidth: POSRefundModalLayout.fullScreenContentMaxWidth)
    }

    var buttonsSection: some View {
        VStack(spacing: POSSpacing.medium) {
            if let onRetry {
                Button(Localization.retryButton, action: onRetry)
                    .buttonStyle(POSFilledButtonStyle(size: .normal))
            }

            Button(cancelButtonTitle ?? Localization.cancelButton, action: onCancel)
                .buttonStyle(POSOutlinedButtonStyle(size: .normal))
        }
        .posCompactFullScreenButtonPadding(horizontalSizeClass: horizontalSizeClass)
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
    .environment(\.posModalParentSize, CGSize(width: 1192, height: 822))
}

#Preview("POSRefundErrorView - Load Error") {
    POSRefundErrorView(
        title: "Couldn't load refund details",
        subtitle: "Please try again.",
        onRetry: {},
        onCancel: {},
        onClose: {}
    )
    .environment(\.posModalParentSize, CGSize(width: 1192, height: 822))
}
#endif
