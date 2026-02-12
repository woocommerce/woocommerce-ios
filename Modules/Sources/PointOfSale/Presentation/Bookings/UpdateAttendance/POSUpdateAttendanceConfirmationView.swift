import SwiftUI

struct POSUpdateAttendanceConfirmationView: View {
    let targetStatus: POSBookingAttendanceDisplay
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

private extension POSUpdateAttendanceConfirmationView {
    var headerView: some View {
        HStack {
            Text(isProcessing ? processingTitle : confirmationTitle)
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
                Text(processingMessage)
            } else {
                Text(bookingDescription)
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
            return String(format: confirmationMessageWithCustomer,
                          serviceName,
                          formattedDateTime,
                          customerName)
        } else {
            return String(format: confirmationMessage,
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
            Button(confirmButton, action: onConfirm)
                .buttonStyle(POSFilledButtonStyle(size: .normal))

            Button(Localization.cancelButton, action: onBack)
                .buttonStyle(POSOutlinedButtonStyle(size: .normal))
        }
        .padding(POSPadding.xLarge)
    }
}

// MARK: - Dynamic Strings

private extension POSUpdateAttendanceConfirmationView {
    var confirmationTitle: String {
        switch targetStatus {
        case .attended:
            return Localization.markAttendedTitle
        case .unattended:
            return Localization.markUnattendedTitle
        }
    }

    var processingTitle: String {
        switch targetStatus {
        case .attended:
            return Localization.markAttendedProcessingTitle
        case .unattended:
            return Localization.markUnattendedProcessingTitle
        }
    }

    var processingMessage: String {
        switch targetStatus {
        case .attended:
            return Localization.markAttendedProcessingMessage
        case .unattended:
            return Localization.markUnattendedProcessingMessage
        }
    }

    var confirmationMessageWithCustomer: String {
        switch targetStatus {
        case .attended:
            return Localization.markAttendedConfirmationMessageWithCustomer
        case .unattended:
            return Localization.markUnattendedConfirmationMessageWithCustomer
        }
    }

    var confirmationMessage: String {
        switch targetStatus {
        case .attended:
            return Localization.markAttendedConfirmationMessage
        case .unattended:
            return Localization.markUnattendedConfirmationMessage
        }
    }

    var confirmButton: String {
        switch targetStatus {
        case .attended:
            return Localization.markAttendedConfirmButton
        case .unattended:
            return Localization.markUnattendedConfirmButton
        }
    }
}

// MARK: - Localization

private extension POSUpdateAttendanceConfirmationView {
    enum Localization {
        // MARK: Mark Attended
        static let markAttendedTitle = NSLocalizedString(
            "pos.updateAttendanceConfirmation.markAttended.title",
            value: "Mark as attended?",
            comment: "Title for the mark attended confirmation modal in POS."
        )

        static let markAttendedProcessingTitle = NSLocalizedString(
            "pos.updateAttendanceConfirmation.markAttended.processingTitle",
            value: "Marking as attended...",
            comment: "Title shown while marking a booking as attended in POS."
        )

        static let markAttendedProcessingMessage = NSLocalizedString(
            "pos.updateAttendanceConfirmation.markAttended.processingMessage",
            value: "Please wait while we update the attendance status.",
            comment: "Message shown while marking a booking as attended in POS."
        )

        static let markAttendedConfirmationMessageWithCustomer = NSLocalizedString(
            "pos.updateAttendanceConfirmation.markAttended.confirmationMessageWithCustomer",
            value: "Mark booking for %1$@ on %2$@ for %3$@ as attended?",
            comment: "Confirmation message with customer name before marking a booking as attended in POS. "
            + "%1$@ is the service name, %2$@ is the date/time, %3$@ is the customer name."
        )

        static let markAttendedConfirmationMessage = NSLocalizedString(
            "pos.updateAttendanceConfirmation.markAttended.confirmationMessage",
            value: "Mark booking for %1$@ on %2$@ as attended?",
            comment: "Confirmation message before marking a booking as attended in POS. "
            + "%1$@ is the service name, %2$@ is the date/time."
        )

        static let markAttendedConfirmButton = NSLocalizedString(
            "pos.updateAttendanceConfirmation.markAttended.confirmButton",
            value: "Yes, mark attended",
            comment: "Button to confirm marking a booking as attended in POS."
        )

        // MARK: Mark Unattended
        static let markUnattendedTitle = NSLocalizedString(
            "pos.updateAttendanceConfirmation.markUnattended.title",
            value: "Mark as unattended?",
            comment: "Title for the mark unattended confirmation modal in POS."
        )

        static let markUnattendedProcessingTitle = NSLocalizedString(
            "pos.updateAttendanceConfirmation.markUnattended.processingTitle",
            value: "Marking as unattended...",
            comment: "Title shown while marking a booking as unattended in POS."
        )

        static let markUnattendedProcessingMessage = NSLocalizedString(
            "pos.updateAttendanceConfirmation.markUnattended.processingMessage",
            value: "Please wait while we update the attendance status.",
            comment: "Message shown while marking a booking as unattended in POS."
        )

        static let markUnattendedConfirmationMessageWithCustomer = NSLocalizedString(
            "pos.updateAttendanceConfirmation.markUnattended.confirmationMessageWithCustomer",
            value: "Mark booking for %1$@ on %2$@ for %3$@ as unattended?",
            comment: "Confirmation message with customer name before marking a booking as unattended in POS. "
            + "%1$@ is the service name, %2$@ is the date/time, %3$@ is the customer name."
        )

        static let markUnattendedConfirmationMessage = NSLocalizedString(
            "pos.updateAttendanceConfirmation.markUnattended.confirmationMessage",
            value: "Mark booking for %1$@ on %2$@ as unattended?",
            comment: "Confirmation message before marking a booking as unattended in POS. "
            + "%1$@ is the service name, %2$@ is the date/time."
        )

        static let markUnattendedConfirmButton = NSLocalizedString(
            "pos.updateAttendanceConfirmation.markUnattended.confirmButton",
            value: "Yes, mark unattended",
            comment: "Button to confirm marking a booking as unattended in POS."
        )

        // MARK: Common
        static let closeButtonAccessibilityLabel = NSLocalizedString(
            "pos.updateAttendanceConfirmation.closeButton.accessibilityLabel",
            value: "Close",
            comment: "Accessibility label for close button on update attendance confirmation modal."
        )

        static let cancelButton = NSLocalizedString(
            "pos.updateAttendanceConfirmation.cancelButton",
            value: "Cancel",
            comment: "Button to dismiss the update attendance confirmation modal in POS."
        )
    }
}

#if DEBUG
#Preview("Mark Attended") {
    POSUpdateAttendanceConfirmationView(
        targetStatus: .attended,
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

#Preview("Mark Unattended") {
    POSUpdateAttendanceConfirmationView(
        targetStatus: .unattended,
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

#Preview("Processing") {
    POSUpdateAttendanceConfirmationView(
        targetStatus: .attended,
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
