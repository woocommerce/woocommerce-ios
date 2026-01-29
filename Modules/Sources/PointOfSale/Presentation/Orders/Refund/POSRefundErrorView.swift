import SwiftUI

struct POSRefundErrorView: View {
    let title: String
    let subtitle: String
    let onRetry: () -> Void
    let onCancel: () -> Void
    let onClose: () -> Void

    @Environment(\.posModalParentSize) private var parentSize

    var body: some View {
        VStack(spacing: POSSpacing.none) {
            headerView
            contentView
            buttonsSection
        }
        .background(Color.posSurfaceBright)
        .clipShape(RoundedRectangle(cornerRadius: POSRefundModalLayout.cornerRadius))
        .frame(width: parentSize.width - (POSRefundModalLayout.horizontalPadding * 2))
    }
}

// MARK: - Subviews

private extension POSRefundErrorView {
    var headerView: some View {
        HStack {
            Spacer()
            Button {
                onClose()
            } label: {
                Text(Image(systemName: "xmark"))
                    .font(.posButtonSymbolLarge)
            }
            .accessibilityLabel(Localization.closeButtonAccessibilityLabel)
        }
        .foregroundColor(Color.posOnSurface)
        .padding(POSPadding.xLarge)
    }

    var contentView: some View {
        VStack(spacing: POSSpacing.medium) {
            POSErrorXMark(size: .large)

            VStack(spacing: POSSpacing.small) {
                Text(title)
                    .font(.posHeadingBold)
                    .foregroundColor(Color.posOnSurface)
                    .accessibilityAddTraits(.isHeader)

                Text(subtitle)
                    .font(.posBodyLargeRegular())
                    .foregroundColor(Color.posOnSurface)
            }
            .multilineTextAlignment(.center)
        }
        .padding(.horizontal, POSPadding.xLarge)
        .padding(.bottom, POSSpacing.xxLarge)
    }

    var buttonsSection: some View {
        VStack(spacing: POSSpacing.medium) {
            Button(Localization.retryButton, action: onRetry)
                .buttonStyle(POSFilledButtonStyle(size: .normal))

            Button(Localization.cancelButton, action: onCancel)
                .buttonStyle(POSOutlinedButtonStyle(size: .normal))
        }
        .padding(POSPadding.xLarge)
    }
}

// MARK: - Localization

private extension POSRefundErrorView {
    enum Localization {
        static let closeButtonAccessibilityLabel = NSLocalizedString(
            "pos.refundErrorView.closeButton.accessibilityLabel",
            value: "Close",
            comment: "Accessibility label for close button on refund error screen"
        )

        static let retryButton = NSLocalizedString(
            "pos.refundErrorView.retryButton",
            value: "Retry",
            comment: "Button to retry after a refund error"
        )

        static let cancelButton = NSLocalizedString(
            "pos.refundErrorView.cancelButton",
            value: "Cancel",
            comment: "Button to cancel after a refund error"
        )
    }
}

// MARK: - Error Types

enum POSRefundErrorType {
    case refundCreation(POSRefundReviewData)

    var title: String {
        switch self {
        case .refundCreation:
            return NSLocalizedString(
                "pos.refundErrorView.refundCreation.title",
                value: "Failed to create refund",
                comment: "Title shown when there's an error creating a refund"
            )
        }
    }

    var subtitle: String {
        NSLocalizedString(
            "pos.refundErrorView.subtitle",
            value: "Please try again.",
            comment: "Subtitle shown on refund error screens"
        )
    }
}

#if DEBUG
#Preview("POSRefundErrorView") {
    POSRefundErrorView(
        title: "Failed to create refund",
        subtitle: "Please try again.",
        onRetry: {},
        onCancel: {},
        onClose: {}
    )
    .environment(\.posModalParentSize, CGSize(width: 1192, height: 822))
}
#endif
