import SwiftUI

struct POSCancelBookingConfirmationView: View {
    let bookingNumber: Int64
    let serviceName: String
    let formattedDateTime: String
    let customerName: String?
    let isProcessing: Bool
    let errorMessage: String?
    let onClose: () -> Void
    let onConfirm: () -> Void
    let onBack: () -> Void

    @Environment(\.posModalParentSize) private var parentSize

    var body: some View {
        VStack(spacing: POSSpacing.none) {
            headerView
            messageView
            buttonsSection
        }
        .background(Color.posSurfaceBright)
        .clipShape(RoundedRectangle(cornerRadius: POSRefundModalLayout.cornerRadius))
        .frame(width: parentSize.width - (POSRefundModalLayout.horizontalPadding * 2))
    }
}

// MARK: - Subviews

private extension POSCancelBookingConfirmationView {
    var headerView: some View {
        VStack(spacing: POSSpacing.medium) {
            HStack {
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

            Text(Localization.title)
                .font(.posHeadingBold)
                .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .foregroundColor(Color.posOnSurface)
        .padding(POSPadding.xLarge)
    }

    var messageView: some View {
        VStack(spacing: POSSpacing.medium) {
            Text(bookingDescription)
            Text(Localization.customerNotificationMessage)
        }
        .font(.posBodyLargeRegular())
        .foregroundColor(Color.posOnSurface)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
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

    var buttonsSection: some View {
        VStack(spacing: POSSpacing.medium) {
            if let errorMessage {
                Text(errorMessage)
                    .font(.posBodyMediumRegular())
                    .foregroundColor(Color.posError)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, POSPadding.xLarge)
            }

            Button(Localization.confirmButton, action: onConfirm)
                .buttonStyle(POSFilledButtonStyle(size: .normal, isLoading: isProcessing))
                .disabled(isProcessing)

            Button(Localization.keepButton, action: onBack)
                .buttonStyle(POSOutlinedButtonStyle(size: .normal))
                .disabled(isProcessing)
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

        static let closeButtonAccessibilityLabel = NSLocalizedString(
            "pos.cancelBookingConfirmation.closeButton.accessibilityLabel",
            value: "Close",
            comment: "Accessibility label for close button on cancel booking confirmation modal."
        )

        static let confirmationMessageWithCustomer = NSLocalizedString(
            "pos.cancelBookingConfirmation.canceled.confirmationMessageWithCustomer",
            value: "Booking #%1$@ for %2$@ on %3$@ for %4$@ will be canceled.",
            comment: "Confirmation message with customer name shown before canceling a booking in POS. "
            + "%1$@ is the booking number, %2$@ is the service name, %3$@ is the date/time, %4$@ is the customer name."
        )

        static let confirmationMessage = NSLocalizedString(
            "pos.cancelBookingConfirmation.canceled.confirmationMessage",
            value: "Booking #%1$@ for %2$@ on %3$@ will be canceled.",
            comment: "Confirmation message shown before canceling a booking in POS. "
            + "%1$@ is the booking number, %2$@ is the service name, %3$@ is the date/time."
        )

        static let customerNotificationMessage = NSLocalizedString(
            "pos.cancelBookingConfirmation.customerNotificationMessage",
            value: "The customer will be notified via email.",
            comment: "Secondary message informing that the customer will receive an email notification about the cancellation."
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
        errorMessage: nil,
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
        errorMessage: nil,
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
        errorMessage: nil,
        onClose: {},
        onConfirm: {},
        onBack: {}
    )
    .environment(\.posModalParentSize, CGSize(width: 1192, height: 822))
}

#Preview("POSCancelBookingConfirmationView - Error") {
    POSCancelBookingConfirmationView(
        bookingNumber: 333,
        serviceName: "Women's Haircut",
        formattedDateTime: "Sep 2, 2026 at 10:30 AM",
        customerName: "Margarita Nikolaevna",
        isProcessing: false,
        errorMessage: "Unable to cancel the booking. Please try again.",
        onClose: {},
        onConfirm: {},
        onBack: {}
    )
    .environment(\.posModalParentSize, CGSize(width: 1192, height: 822))
}
#endif
