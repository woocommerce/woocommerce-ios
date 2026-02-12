import SwiftUI

struct POSCancelBookingConfirmationView: View {
    let bookingNumber: Int64
    let serviceName: String
    let formattedDateTime: String
    let customerName: String?
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
        VStack(alignment: .leading, spacing: POSSpacing.small) {
            if isProcessing {
                Text(Localization.processingMessage)
            } else {
                Text(bookingDescription)
                Text(Localization.customerNotificationMessage)
            }
        }
        .font(.posBodyLargeRegular())
        .foregroundColor(Color.posOnSurface)
        .multilineTextAlignment(.leading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, POSPadding.xLarge)
    }

    private var bookingDescription: String {
        if let customerName {
            return String(format: Localization.confirmationMessageWithCustomer,
                          String(bookingNumber),
                          serviceName,
                          formattedDateTime,
                          customerName)
        } else {
            return String(format: Localization.confirmationMessage,
                          String(bookingNumber),
                          serviceName,
                          formattedDateTime)
        }
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

            Button(Localization.keepButton, action: onBack)
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
            value: "Cancel this booking?",
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

        static let confirmationMessageWithCustomer = NSLocalizedString(
            "pos.cancelBookingConfirmation.confirmationMessageWithCustomer",
            value: "Booking #%1$@ for %2$@ on %3$@ for %4$@ will be cancelled.",
            comment: "Confirmation message with customer name shown before cancelling a booking in POS. "
            + "%1$@ is the booking number, %2$@ is the service name, %3$@ is the date/time, %4$@ is the customer name."
        )

        static let confirmationMessage = NSLocalizedString(
            "pos.cancelBookingConfirmation.confirmationMessage",
            value: "Booking #%1$@ for %2$@ on %3$@ will be cancelled.",
            comment: "Confirmation message shown before cancelling a booking in POS. "
            + "%1$@ is the booking number, %2$@ is the service name, %3$@ is the date/time."
        )

        static let customerNotificationMessage = NSLocalizedString(
            "pos.cancelBookingConfirmation.customerNotificationMessage",
            value: "The customer will be notified via email.",
            comment: "Secondary message informing that the customer will receive an email notification about the cancellation."
        )

        static let processingMessage = NSLocalizedString(
            "pos.cancelBookingConfirmation.processingMessage",
            value: "Please wait while we cancel the booking.",
            comment: "Message shown while the booking cancellation is being processed."
        )

        static let confirmButton = NSLocalizedString(
            "pos.cancelBookingConfirmation.confirmButton",
            value: "Yes, cancel booking",
            comment: "Button to confirm and proceed with booking cancellation."
        )

        static let keepButton = NSLocalizedString(
            "pos.cancelBookingConfirmation.keepButton",
            value: "No, keep it",
            comment: "Button to dismiss the cancel booking confirmation and keep the booking."
        )
    }
}

#if DEBUG
#Preview("POSCancelBookingConfirmationView") {
    POSCancelBookingConfirmationView(
        bookingNumber: 123,
        serviceName: "Haircut",
        formattedDateTime: "Jan 15, 2026 at 2:00 PM",
        customerName: "John Smith",
        isProcessing: false,
        onClose: {},
        onConfirm: {},
        onBack: {}
    )
    .environment(\.posModalParentSize, CGSize(width: 1192, height: 822))
}

#Preview("POSCancelBookingConfirmationView - No Customer") {
    POSCancelBookingConfirmationView(
        bookingNumber: 456,
        serviceName: "Massage",
        formattedDateTime: "Feb 10, 2026 at 10:00 AM",
        customerName: nil,
        isProcessing: false,
        onClose: {},
        onConfirm: {},
        onBack: {}
    )
    .environment(\.posModalParentSize, CGSize(width: 1192, height: 822))
}

#Preview("POSCancelBookingConfirmationView - Processing") {
    POSCancelBookingConfirmationView(
        bookingNumber: 123,
        serviceName: "Haircut",
        formattedDateTime: "Jan 15, 2026 at 2:00 PM",
        customerName: "John Smith",
        isProcessing: true,
        onClose: {},
        onConfirm: {},
        onBack: {}
    )
    .environment(\.posModalParentSize, CGSize(width: 1192, height: 822))
}
#endif
