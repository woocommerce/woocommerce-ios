import SwiftUI
import struct WooFoundation.WooAnalyticsEvent
import struct Yosemite.POSBooking

struct POSCancelBookingModalContent: View {
    let booking: POSBooking
    @Binding var showCancelModal: Bool
    let onSuccess: () -> Void

    @Environment(POSBookingsModel.self) private var bookingsModel
    @Environment(\.posAnalytics) private var analytics

    @State private var isProcessing = false
    @State private var errorMessage: String?

    var body: some View {
        POSCancelBookingConfirmationView(
            bookingNumber: booking.id,
            serviceName: booking.serviceName,
            formattedDateTime: POSBookingDateFormatter.formattedDateTime(for: booking.startDate),
            customerName: booking.customerName,
            isProcessing: isProcessing,
            errorMessage: errorMessage,
            onClose: { showCancelModal = false },
            onConfirm: {
                isProcessing = true
                errorMessage = nil
                Task { @MainActor in
                    await performCancelBooking()
                }
            },
            onBack: { showCancelModal = false }
        )
    }

    @MainActor
    private func performCancelBooking() async {
        do {
            try await bookingsModel.bookingsController.cancelBooking(bookingID: booking.id)
            analytics.track(event: WooAnalyticsEvent.PointOfSale.bookingCancelled())
            onSuccess()
        } catch {
            analytics.track(event: WooAnalyticsEvent.PointOfSale.bookingCancelFailed(error: error))
            errorMessage = Localization.cancelBookingInlineError
            isProcessing = false
        }
    }
}

// MARK: - Localization

private enum Localization {
    static let cancelBookingInlineError = NSLocalizedString(
        "pos.cancelBookingConfirmation.inlineErrorMessage",
        value: "Unable to cancel the booking. Please try again.",
        comment: "Error message shown inline in the cancel booking confirmation modal when cancellation fails."
    )
}
