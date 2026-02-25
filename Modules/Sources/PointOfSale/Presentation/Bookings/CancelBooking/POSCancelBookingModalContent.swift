import SwiftUI
import struct WooFoundation.WooAnalyticsEvent
import struct Yosemite.POSBooking

struct POSCancelBookingModalContent: View {
    let state: CancelBookingModalState
    let booking: POSBooking
    @Binding var cancelModalState: CancelBookingModalState?

    @Environment(POSBookingsModel.self) private var bookingsModel
    @Environment(\.posAnalytics) private var analytics
    @Environment(\.siteTimezone) private var siteTimezone

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

    private static let cancelDateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    private var formattedCancelDateTime: String {
        Self.cancelDateTimeFormatter.timeZone = siteTimezone
        return Self.cancelDateTimeFormatter.string(from: booking.startDate)
    }

    @MainActor
    private func performCancelBooking() async {
        do {
            try await bookingsModel.bookingsController.cancelBooking(bookingID: booking.id)
            analytics.track(event: WooAnalyticsEvent.PointOfSale.bookingCancelled(bookingID: booking.id))
            cancelModalState = .success
        } catch {
            cancelModalState = .error
        }
    }
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
