import SwiftUI

struct POSCancelBookingConfirmationView: View {
    let isProcessing: Bool
    let onClose: () -> Void
    let onConfirm: () -> Void
    let onBack: () -> Void

    @Environment(\.posModalParentSize) private var parentSize

    var body: some View {
        VStack(spacing: POSSpacing.none) {
            headerView
            messageView
            if isProcessing {
                loadingSection
            } else {
                buttonsSection
            }
        }
        .background(Color.posSurfaceBright)
        .clipShape(RoundedRectangle(cornerRadius: POSRefundModalLayout.cornerRadius))
        .frame(width: parentSize.width - (POSRefundModalLayout.horizontalPadding * 2))
    }
}

// MARK: - Subviews

private extension POSCancelBookingConfirmationView {
    var headerView: some View {
        HStack {
            Text(isProcessing ? Localization.processingTitle : Localization.title)
                .font(.posHeadingBold)
                .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                .lineLimit(1)
            Spacer()
            Button {
                onClose()
            } label: {
                Text(Image(systemName: "xmark"))
                    .font(.posButtonSymbolLarge)
            }
            .accessibilityLabel(Localization.closeButtonAccessibilityLabel)
            .disabled(isProcessing)
            .opacity(isProcessing ? 0.5 : 1.0)
        }
        .foregroundColor(Color.posOnSurface)
        .padding(POSPadding.xLarge)
    }

    var messageView: some View {
        Text(isProcessing ? Localization.processingMessage : Localization.confirmationMessage)
            .font(.posBodyLargeRegular())
            .foregroundColor(Color.posOnSurface)
            .multilineTextAlignment(.leading)
            .padding(.horizontal, POSPadding.xLarge)
    }

    var loadingSection: some View {
        VStack {
            ProgressView()
                .progressViewStyle(POSRefundModalLayout.progressViewStyle)
        }
        .frame(maxWidth: .infinity)
        .padding(POSPadding.xLarge)
    }

    var buttonsSection: some View {
        VStack(spacing: POSSpacing.medium) {
            Button(Localization.confirmButton, action: onConfirm)
                .buttonStyle(POSFilledButtonStyle(size: .normal))

            Button(Localization.backButton, action: onBack)
                .buttonStyle(POSOutlinedButtonStyle(size: .normal))
        }
        .padding(POSPadding.xLarge)
    }
}

// MARK: - Localization

private extension POSCancelBookingConfirmationView {
    enum Localization {
        static let title = NSLocalizedString(
            "pos.cancelBookingConfirmation.title",
            value: "Cancel Booking",
            comment: "Title for the cancel booking confirmation modal in POS."
        )

        static let processingTitle = NSLocalizedString(
            "pos.cancelBookingConfirmation.processingTitle",
            value: "Cancelling booking...",
            comment: "Title shown while a booking cancellation is being processed in POS."
        )

        static let closeButtonAccessibilityLabel = NSLocalizedString(
            "pos.cancelBookingConfirmation.closeButton.accessibilityLabel",
            value: "Close",
            comment: "Accessibility label for close button on cancel booking confirmation modal."
        )

        static let confirmationMessage = NSLocalizedString(
            "pos.cancelBookingConfirmation.confirmationMessage",
            value: "Are you sure you want to cancel this booking? This action cannot be undone.",
            comment: "Confirmation message shown before cancelling a booking in POS."
        )

        static let processingMessage = NSLocalizedString(
            "pos.cancelBookingConfirmation.processingMessage",
            value: "Please wait while we cancel the booking.",
            comment: "Message shown while the booking cancellation is being processed."
        )

        static let confirmButton = NSLocalizedString(
            "pos.cancelBookingConfirmation.confirmButton",
            value: "Yes, proceed",
            comment: "Button to confirm and proceed with booking cancellation."
        )

        static let backButton = NSLocalizedString(
            "pos.cancelBookingConfirmation.backButton",
            value: "Back",
            comment: "Button to go back from the cancel booking confirmation modal."
        )
    }
}

#if DEBUG
#Preview("POSCancelBookingConfirmationView") {
    POSCancelBookingConfirmationView(
        isProcessing: false,
        onClose: {},
        onConfirm: {},
        onBack: {}
    )
    .environment(\.posModalParentSize, CGSize(width: 1192, height: 822))
}

#Preview("POSCancelBookingConfirmationView - Processing") {
    POSCancelBookingConfirmationView(
        isProcessing: true,
        onClose: {},
        onConfirm: {},
        onBack: {}
    )
    .environment(\.posModalParentSize, CGSize(width: 1192, height: 822))
}
#endif
