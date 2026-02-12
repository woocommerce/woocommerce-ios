import SwiftUI
import struct Yosemite.POSBooking

struct POSCancelBookingModalContent: View {
    let state: CancelBookingModalState
    let booking: POSBooking
    @Binding var cancelModalState: CancelBookingModalState?

    @Environment(POSBookingsModel.self) private var bookingsModel

    var body: some View {
        switch state {
        case .confirmation:
            POSCancelBookingConfirmationView(
                bookingNumber: booking.id,
                serviceName: booking.serviceName,
                formattedDateTime: formattedCancelDateTime,
                customerName: booking.customerName,
                isProcessing: false,
                onClose: { cancelModalState = nil },
                onConfirm: {
                    cancelModalState = .processing
                    Task { @MainActor in
                        await performCancelBooking()
                    }
                },
                onBack: { cancelModalState = nil }
            )
        case .processing:
            POSCancelBookingConfirmationView(
                bookingNumber: booking.id,
                serviceName: booking.serviceName,
                formattedDateTime: formattedCancelDateTime,
                customerName: booking.customerName,
                isProcessing: true,
                onClose: {},
                onConfirm: {},
                onBack: {}
            )
        case .success:
            POSCancelBookingSuccessView(
                onDone: { cancelModalState = nil },
                onClose: { cancelModalState = nil }
            )
        case .error:
            POSRefundErrorView(
                title: Localization.cancelBookingErrorTitle,
                subtitle: Localization.cancelBookingErrorSubtitle,
                onRetry: {
                    cancelModalState = .processing
                    Task { @MainActor in
                        await performCancelBooking()
                    }
                },
                onCancel: { cancelModalState = nil },
                onClose: { cancelModalState = nil }
            )
        }
    }

    private var formattedCancelDateTime: String {
        DateFormatter.dateTimeFormatter.string(from: booking.startDate)
    }

    @MainActor
    private func performCancelBooking() async {
        do {
            try await bookingsModel.bookingsController.cancelBooking(bookingID: booking.id)
            cancelModalState = .success
        } catch {
            cancelModalState = .error
        }
    }
}

// MARK: - Date Formatters

private extension DateFormatter {
    static let dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

// MARK: - Localization

private enum Localization {
    static let cancelBookingErrorTitle = NSLocalizedString(
        "pos.bookingDetailView.cancelBookingError.title",
        value: "Failed to cancel booking",
        comment: "Title shown when cancelling a booking from POS has failed."
    )

    static let cancelBookingErrorSubtitle = NSLocalizedString(
        "pos.bookingDetailView.cancelBookingError.subtitle",
        value: "Please try again.",
        comment: "Subtitle shown when cancelling a booking from POS has failed."
    )
}
