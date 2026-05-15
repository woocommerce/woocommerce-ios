import SwiftUI

struct POSRefundErrorView: View {
    let title: String
    let subtitle: String
    let onRetry: () -> Void
    let onCancel: () -> Void
    let onClose: () -> Void

    @Environment(\.posModalParentSize) private var parentSize
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var isViewLoaded: Bool = false

    var body: some View {
        VStack(spacing: POSSpacing.none) {
            headerView
            contentView
            buttonsSection
        }
        .background(Color.posSurfaceBright)
        .posRefundModalFrame(parentSize: parentSize, horizontalSizeClass: horizontalSizeClass)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                isViewLoaded = true
            }
        }
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
        VStack(spacing: POSSpacing.xLarge) {
            POSErrorXMark()
                .scaleEffect(isViewLoaded ? 1 : 0)
                .opacity(isViewLoaded ? 1 : 0)

            VStack(spacing: POSSpacing.small) {
                Text(title)
                    .font(.posHeadingBold)
                    .foregroundColor(Color.posOnSurface)
                    .accessibilityAddTraits(.isHeader)
                    .offset(y: isViewLoaded ? 0 : Constants.animationOffset)
                    .opacity(isViewLoaded ? 1 : 0)

                Text(subtitle)
                    .font(.posBodyLargeRegular())
                    .foregroundColor(Color.posOnSurface)
                    .offset(y: isViewLoaded ? 0 : Constants.animationOffset)
                    .opacity(isViewLoaded ? 1 : 0)
            }
            .multilineTextAlignment(.center)
        }
        .padding(.horizontal, POSPadding.xLarge)
        .padding(.bottom, POSSpacing.xLarge)
    }

    var buttonsSection: some View {
        VStack(spacing: POSSpacing.medium) {
            Button(Localization.retryButton, action: onRetry)
                .buttonStyle(POSFilledButtonStyle(size: .normal))

            Button(Localization.cancelButton, action: onCancel)
                .buttonStyle(POSOutlinedButtonStyle(size: .normal))
        }
        .posPhoneFullScreenButtonPadding(horizontalSizeClass: horizontalSizeClass)
        .offset(y: isViewLoaded ? 0 : -Constants.animationOffset)
        .opacity(isViewLoaded ? 1 : 0)
    }
}

// MARK: - Constants

private extension POSRefundErrorView {
    enum Constants {
        static let animationOffset: CGFloat = 100
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
